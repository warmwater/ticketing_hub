module Organizer
  class EventsController < Organizer::ApplicationController
    before_action :set_event, only: [ :show, :edit, :update, :destroy, :publish, :cancel, :toggle_waiting_room, :purge_attachment ]

    def index
      @pagy, @events = pagy(
        current_user.organized_events.includes(:venue).order(created_at: :desc)
      )
    end

    def show
      @ticket_types = @event.ticket_types.includes(:section)
      @recent_orders = @event.orders.includes(:user).order(created_at: :desc).limit(20)
      @waiting_count = @event.waiting_room_entries.waiting.count

      # Load seating layout if venue has sections
      if @event.venue&.has_seating?
        @sections = @event.venue.sections.ordered.includes(:seats)
      end
    end

    def new
      @event = current_user.organized_events.build
      @venues = Venue.ordered
    end

    def create
      @event = current_user.organized_events.build(event_params)

      if @event.save
        redirect_to organizer_event_path(@event), notice: t("flash.organizer.event_created")
      else
        @venues = Venue.ordered
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @venues = Venue.ordered
    end

    def update
      @event.cover_image.purge if params[:event][:remove_cover_image] == "1"

      # Append new media files instead of replacing
      new_media = params[:event]&.delete(:media)

      if @event.update(event_params)
        @event.media.attach(new_media) if new_media.present?
        redirect_to organizer_event_path(@event), notice: t("flash.organizer.event_updated")
      else
        @venues = Venue.ordered
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @event.destroy
      redirect_to organizer_events_path, notice: t("flash.organizer.event_deleted")
    end

    def publish
      @event.published!
      redirect_to organizer_event_path(@event), notice: t("flash.organizer.event_published")
    end

    def cancel
      @event.cancelled!
      redirect_to organizer_event_path(@event), notice: t("flash.organizer.event_cancelled")
    end

    def toggle_waiting_room
      @event.update!(waiting_room_enabled: !@event.waiting_room_enabled)
      status = @event.waiting_room_enabled? ? "enabled" : "disabled"
      redirect_to organizer_event_path(@event), notice: t("flash.organizer.waiting_room_toggled", status: status)
    end

    def purge_attachment
      attachment = ActiveStorage::Attachment.find(params[:attachment_id])
      if attachment.record == @event
        attachment.purge
        redirect_back fallback_location: edit_organizer_event_path(@event), notice: t("flash.organizer.file_removed")
      else
        redirect_back fallback_location: edit_organizer_event_path(@event), alert: t("flash.organizer.attachment_not_found")
      end
    end

    private

    def set_event
      @event = current_user.organized_events.find(params[:id])
    end

    def event_params
      params.require(:event).permit(:name, :description, :starts_at, :ends_at, :venue_id,
                                    :waiting_room_enabled, :waiting_room_capacity,
                                    :waiting_room_admission_minutes, :max_tickets_per_order,
                                    :max_tickets_per_user, :seat_selection_mode, :cover_image)
    end
  end
end
