module Admin
  class VenueSectionsController < Admin::ApplicationController
    before_action :set_venue
    before_action :set_section, only: [ :update, :destroy, :generate_seats ]

    def create
      @section = @venue.sections.build(section_params)

      if @section.save
        redirect_to admin_venue_path(@venue), notice: "Section '#{@section.name}' added."
      else
        redirect_to admin_venue_path(@venue), alert: @section.errors.full_messages.join(", ")
      end
    end

    def update
      if @section.update(section_params)
        redirect_to admin_venue_path(@venue), notice: "Section updated."
      else
        redirect_to admin_venue_path(@venue), alert: @section.errors.full_messages.join(", ")
      end
    end

    def destroy
      if @section.destroy
        redirect_to admin_venue_path(@venue), notice: "Section removed."
      else
        redirect_to admin_venue_path(@venue), alert: @section.errors.full_messages.join(", ")
      end
    end

    def generate_seats
      row_labels = params[:row_labels].to_s.split(",").map(&:strip).reject(&:blank?)
      seats_per_row = params[:seats_per_row].to_i

      if row_labels.empty? || seats_per_row <= 0
        redirect_to admin_venue_path(@venue), alert: "Please provide row labels and seats per row."
        return
      end

      count = 0
      row_labels.each do |row|
        (1..seats_per_row).each do |num|
          @section.seats.find_or_create_by!(row_label: row, seat_number: num)
          count += 1
        end
      end

      @section.update!(capacity: @section.active_seats.count)
      redirect_to admin_venue_path(@venue), notice: "#{@section.active_seats.count} seats generated for '#{@section.name}'."
    end

    private

    def set_venue
      @venue = Venue.find(params[:venue_id])
    end

    def set_section
      @section = @venue.sections.find(params[:id])
    end

    def section_params
      params.require(:section).permit(:name, :section_type, :capacity, :position)
    end
  end
end
