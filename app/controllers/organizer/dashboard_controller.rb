module Organizer
  class DashboardController < Organizer::ApplicationController
    def index
      @events = current_user.organized_events.order(created_at: :desc).limit(10)
      @total_events = current_user.organized_events.count
      @total_tickets_sold = current_user.organized_events
        .joins(ticket_types: { order_items: :tickets })
        .where(tickets: { status: [:active, :used] })
        .count("tickets.id")
      @upcoming_events = current_user.organized_events.upcoming.limit(5)
    end
  end
end
