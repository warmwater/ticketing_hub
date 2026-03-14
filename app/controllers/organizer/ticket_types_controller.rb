module Organizer
  class TicketTypesController < Organizer::ApplicationController
    before_action :set_event
    before_action :set_ticket_type, only: [ :edit, :update, :destroy ]

    def index
      @ticket_types = @event.ticket_types.order(:created_at)
    end

    def new
      @ticket_type = @event.ticket_types.build
    end

    def create
      @ticket_type = @event.ticket_types.build(ticket_type_params)

      if @ticket_type.save
        redirect_to organizer_event_path(@event), notice: t("flash.organizer.ticket_type_created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @ticket_type.update(ticket_type_params)
        redirect_to organizer_event_path(@event), notice: t("flash.organizer.ticket_type_updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @ticket_type.destroy
        redirect_to organizer_event_path(@event), notice: t("flash.organizer.ticket_type_deleted")
      else
        redirect_to organizer_event_path(@event), alert: @ticket_type.errors.full_messages.join(", ")
      end
    end

    private

    def set_event
      @event = current_user.organized_events.find(params[:event_id])
    end

    def set_ticket_type
      @ticket_type = @event.ticket_types.find(params[:id])
    end

    def ticket_type_params
      params.require(:ticket_type).permit(:name, :description, :price, :quantity,
                                          :max_per_order, :sale_starts_at, :sale_ends_at,
                                          :section_id)
    end
  end
end
