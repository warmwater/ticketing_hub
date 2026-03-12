class EventsController < ApplicationController
  def index
    events = Event.published_events.includes(:venue, :ticket_types)
    events = events.where("name LIKE ?", "%#{params[:q]}%") if params[:q].present?
    @pagy, @events = pagy(events, items: 12)
  end

  def show
    @event = Event.published.find(params[:id])
    @ticket_types = @event.ticket_types.on_sale

    if @event.waiting_room_active? && current_user
      @waiting_entry = @event.waiting_room_entries.find_by(user: current_user)
    end

    # Load seating layout if venue has sections
    if @event.venue&.has_seating?
      @sections = @event.venue.sections.ordered.includes(:seats)
    end
  end
end
