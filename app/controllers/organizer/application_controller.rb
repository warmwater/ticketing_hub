module Organizer
  class ApplicationController < ::ApplicationController
    before_action :authenticate_user!
    before_action :require_organizer!
    layout "organizer"

    private

    def require_organizer!
      unless current_user.organizer? || current_user.admin?
        redirect_to root_path, alert: "Access denied."
      end
    end
  end
end
