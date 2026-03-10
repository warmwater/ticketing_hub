module Organizer
  class OrdersController < Organizer::ApplicationController
    def index
      events = current_user.organized_events.select(:id)
      @pagy, @orders = pagy(
        Order.where(event_id: events).includes(:user, :event).order(created_at: :desc)
      )
    end

    def show
      events = current_user.organized_events.select(:id)
      @order = Order.where(event_id: events).includes(order_items: [:ticket_type, :tickets]).find(params[:id])
    end
  end
end
