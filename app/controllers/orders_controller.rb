class OrdersController < ApplicationController
  before_action :authenticate_user!

  def index
    @orders = current_user.orders.includes(event: :venue).order(created_at: :desc)
  end

  def show
    @order = current_user.orders.includes(order_items: [:ticket_type, :tickets]).find(params[:id])
  end

  def new
    @event = Event.published.find(params[:event_id])

    if @event.waiting_room_active?
      entry = @event.waiting_room_entries.find_by(user: current_user)
      unless entry&.admitted? && !entry.admission_expired?
        redirect_to event_waiting_room_path(@event), alert: "Please join the waiting room first."
        return
      end
    end

    @order = @event.orders.build
    @ticket_types = @event.ticket_types.on_sale
  end

  def create
    @event = Event.published.find(params[:event_id])

    if @event.waiting_room_active?
      entry = @event.waiting_room_entries.find_by(user: current_user)
      unless entry&.admitted? && !entry.admission_expired?
        redirect_to event_waiting_room_path(@event), alert: "Your admission has expired."
        return
      end
    end

    @order = @event.orders.build(user: current_user)
    build_order_items

    if @order.order_items.empty?
      redirect_to event_path(@event), alert: "Please select at least one ticket."
      return
    end

    @order.calculate_total

    if @order.save
      @order.update!(status: :confirmed) # auto-confirm since payment is later
      @order.generate_tickets!

      # Mark waiting room entry as completed and clear middleware cookies
      entry = @event.waiting_room_entries.find_by(user: current_user)
      entry&.update!(status: :completed)
      clear_waiting_room_cookies(@event)

      # Trigger next user admission
      AdmitNextUserJob.perform_later(@event.id)

      redirect_to order_path(@order), notice: "Order placed successfully! Tickets have been generated."
    else
      @ticket_types = @event.ticket_types.on_sale
      render :new, status: :unprocessable_entity
    end
  end

  private

  def clear_waiting_room_cookies(event)
    cookies.delete("_wr_queue_#{event.id}", path: "/events/#{event.id}")
    cookies.delete("_wr_admitted_#{event.id}", path: "/events/#{event.id}")
  end

  def build_order_items
    return unless params[:ticket_quantities]

    params[:ticket_quantities].each do |ticket_type_id, quantity|
      qty = quantity.to_i
      next if qty <= 0

      ticket_type = @event.ticket_types.find(ticket_type_id)
      next unless ticket_type.available? && qty <= ticket_type.available_quantity
      next if qty > ticket_type.max_per_order

      @order.order_items.build(
        ticket_type: ticket_type,
        quantity: qty,
        unit_price: ticket_type.price
      )
    end
  end
end
