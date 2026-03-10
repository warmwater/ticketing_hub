module Admin
  class DashboardController < Admin::ApplicationController
    def index
      @total_users = User.count
      @total_events = Event.count
      @total_venues = Venue.count
      @total_orders = Order.confirmed.count
      @total_tickets = Ticket.active.count
      @recent_events = Event.order(created_at: :desc).limit(5).includes(:organizer, :venue)
      @recent_orders = Order.order(created_at: :desc).limit(10).includes(:user, :event)
    end
  end
end
