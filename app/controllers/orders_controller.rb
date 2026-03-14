class OrdersController < ApplicationController
  before_action :authenticate_user!

  def index
    @orders = current_user.orders.includes(event: :venue).order(created_at: :desc)
  end

  def show
    @order = current_user.orders.includes(order_items: [ :ticket_type, :tickets ]).find(params[:id])
  end

  def new
    @event = Event.published.find(params[:event_id])

    if @event.waiting_room_active?
      entry = @event.waiting_room_entries.find_by(user: current_user)
      unless entry&.admitted? && !entry.admission_expired?
        redirect_to event_waiting_room_path(@event), alert: t("flash.join_waiting_room")
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
        redirect_to event_waiting_room_path(@event), alert: t("flash.admission_expired")
        return
      end
    end

    # For customer_pick, seats come from the seat selection step
    if @event.seating_customer_pick? && params[:seat_selections].present?
      return handle_customer_pick_order
    end

    @order = @event.orders.build(user: current_user)
    build_order_items

    if @order.order_items.empty?
      redirect_to event_path(@event), alert: t("flash.select_ticket")
      return
    end

    # For customer_pick events, redirect to seat selection page instead of creating order
    if @event.seating_customer_pick?
      session[:pending_ticket_quantities] = params[:ticket_quantities].to_unsafe_h
      redirect_to select_seats_event_orders_path(@event)
      return
    end

    @order.calculate_total

    if @order.save
      @order.update!(status: :confirmed)

      # Build seat assignments for auto-assign mode
      seat_assignments = {}
      if @event.seating_auto_assign?
        seat_assignments = auto_assign_seats(@order)
      end

      @order.generate_tickets!(seat_assignments)
      @order.broadcast_taken_seats

      # Mark waiting room entry as completed and clear middleware cookies
      entry = @event.waiting_room_entries.find_by(user: current_user)
      entry&.update!(status: :completed)
      clear_waiting_room_cookies(@event)

      # Trigger next user admission
      AdmitNextUserJob.perform_later(@event.id)

      redirect_to order_path(@order), notice: t("flash.order_success")
    else
      @ticket_types = @event.ticket_types.on_sale
      render :new, status: :unprocessable_entity
    end
  end

  def select_seats
    @event = Event.published.find(params[:event_id])
    @ticket_quantities = session[:pending_ticket_quantities] || {}

    unless @event.seating_customer_pick?
      redirect_to event_path(@event), alert: t("flash.seat_selection_unavailable")
      return
    end

    if @ticket_quantities.empty?
      redirect_to event_path(@event), alert: t("flash.select_tickets_first")
      return
    end

    # Build ticket types and sections with available seats
    @selections = []
    @ticket_quantities.each do |ticket_type_id, quantity|
      qty = quantity.to_i
      next if qty <= 0

      ticket_type = @event.ticket_types.find(ticket_type_id)
      section = ticket_type.section
      next unless section&.seated?

      available_seats = section.available_seats_for_event(@event)
      rows = available_seats.group_by(&:row_label)

      @selections << {
        ticket_type: ticket_type,
        section: section,
        quantity: qty,
        rows: rows,
        all_seats: section.seats.where(active: true).order(:row_label, :seat_number),
        taken_seat_ids: section.seats.where(active: true).pluck(:id) - available_seats.pluck(:id)
      }
    end
  end

  private

  def handle_customer_pick_order
    @order = @event.orders.build(user: current_user)
    ticket_quantities = session.delete(:pending_ticket_quantities) || {}

    ticket_quantities.each do |ticket_type_id, quantity|
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

    if @order.order_items.empty?
      redirect_to event_path(@event), alert: t("flash.select_ticket")
      return
    end

    # Parse seat selections: { ticket_type_id => [seat_id, seat_id, ...] }
    seat_assignments = {}
    params[:seat_selections].each do |ticket_type_id, seat_ids|
      seats = Seat.where(id: seat_ids).order(:row_label, :seat_number)
      seat_assignments[ticket_type_id.to_s] = seats.to_a
    end

    @order.calculate_total

    if @order.save
      @order.update!(status: :confirmed)
      @order.generate_tickets!(seat_assignments)
      @order.broadcast_taken_seats

      # Mark waiting room entry as completed and clear middleware cookies
      entry = @event.waiting_room_entries.find_by(user: current_user)
      entry&.update!(status: :completed)
      clear_waiting_room_cookies(@event)

      AdmitNextUserJob.perform_later(@event.id)

      redirect_to order_path(@order), notice: t("flash.order_success_seats")
    else
      redirect_to event_path(@event), alert: @order.errors.full_messages.join(", ")
    end
  end

  def auto_assign_seats(order)
    assignments = {}

    order.order_items.each do |item|
      section = item.ticket_type.section
      next unless section&.seated?

      available = section.available_seats_for_event(@event).limit(item.quantity).to_a

      if available.size < item.quantity
        raise ActiveRecord::Rollback, "Not enough seats available in #{section.name}"
      end

      assignments[item.ticket_type_id.to_s] = available
    end

    assignments
  end

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
