class TicketsController < ApplicationController
  before_action :authenticate_user!

  def index
    @tickets = Ticket.joins(order_item: { ticket_type: :event }, order: {})
                     .where(order_items: { orders: { user_id: current_user.id } })
                     .includes(ticket_type: :event)
                     .order(created_at: :desc)
  end

  def show
    @ticket = Ticket.joins(order_item: :order)
                    .where(order_items: { orders: { user_id: current_user.id } })
                    .find(params[:id])
  end
end
