class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :turbo_native_app?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def turbo_native_app?
    request.user_agent&.include?("Turbo Native")
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :phone])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :phone])
  end

  def after_sign_in_path_for(resource)
    case resource.role
    when "admin" then admin_root_path
    when "organizer" then organizer_root_path
    else root_path
    end
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end
end
