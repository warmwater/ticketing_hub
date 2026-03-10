module Admin
  class VenuesController < Admin::ApplicationController
    before_action :set_venue, only: [:show, :edit, :update, :destroy]

    def index
      @pagy, @venues = pagy(Venue.ordered.includes(:created_by))
    end

    def show
      @events = @venue.events.includes(:organizer).order(starts_at: :desc)
    end

    def new
      @venue = Venue.new
    end

    def create
      @venue = Venue.new(venue_params)
      @venue.created_by = current_user

      if @venue.save
        redirect_to admin_venue_path(@venue), notice: "Venue created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @venue.update(venue_params)
        redirect_to admin_venue_path(@venue), notice: "Venue updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @venue.destroy
        redirect_to admin_venues_path, notice: "Venue deleted."
      else
        redirect_to admin_venue_path(@venue), alert: @venue.errors.full_messages.join(", ")
      end
    end

    private

    def set_venue
      @venue = Venue.find(params[:id])
    end

    def venue_params
      params.require(:venue).permit(:name, :address, :city, :state, :country, :capacity, :description)
    end
  end
end
