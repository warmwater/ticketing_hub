module Admin
  class EventsController < Admin::ApplicationController
    before_action :set_event, only: [ :show, :edit, :update, :destroy, :publish, :cancel, :purge_attachment ]

    def index
      events = Event.includes(:organizer, :venue).order(created_at: :desc)
      events = events.where(status: params[:status]) if params[:status].present?
      @pagy, @events = pagy(events)
    end

    def show
      @ticket_types = @event.ticket_types.includes(:section)
      @orders = @event.orders.includes(:user).order(created_at: :desc).limit(20)

      if @event.venue&.has_seating?
        @sections = @event.venue.sections.ordered.includes(:seats)
      end
    end

    def edit
    end

    def update
      @event.cover_image.purge if params[:event][:remove_cover_image] == "1"

      # Append new media files instead of replacing
      new_media = params[:event]&.delete(:media)

      if @event.update(event_params)
        @event.media.attach(new_media) if new_media.present?
        redirect_to admin_event_path(@event), notice: t("flash.admin.event_updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @event.destroy
      redirect_to admin_events_path, notice: t("flash.admin.event_deleted")
    end

    def publish
      @event.published!
      redirect_to admin_event_path(@event), notice: t("flash.admin.event_published")
    end

    def cancel
      @event.cancelled!
      redirect_to admin_event_path(@event), notice: t("flash.admin.event_cancelled")
    end

    def purge_attachment
      attachment = ActiveStorage::Attachment.find(params[:attachment_id])
      if attachment.record == @event
        attachment.purge
        redirect_back fallback_location: edit_admin_event_path(@event), notice: t("flash.admin.file_removed")
      else
        redirect_back fallback_location: edit_admin_event_path(@event), alert: t("flash.admin.attachment_not_found")
      end
    end

    private

    def set_event
      @event = Event.find(params[:id])
    end

    def event_params
      params.require(:event).permit(:name, :description, :starts_at, :ends_at, :venue_id, :status,
                                    :waiting_room_enabled, :waiting_room_capacity,
                                    :waiting_room_admission_minutes, :max_tickets_per_order,
                                    :max_tickets_per_user, :cover_image, :seat_selection_mode)
    end
  end
end
