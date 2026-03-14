class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :turbo_native_app?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def turbo_native_app?
    request.user_agent&.include?("Turbo Native")
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :phone ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :phone ])
  end

  def after_sign_in_path_for(resource)
    case resource.role
    when "admin" then admin_root_path
    when "organizer" then organizer_root_path
    else root_path
    end
  end

  def user_not_authorized
    flash[:alert] = t("flash.unauthorized")
    redirect_back(fallback_location: root_path)
  end

  def set_locale
    I18n.locale = extract_locale || I18n.default_locale
  end

  def extract_locale
    # 1. Cookie
    cookie_locale = cookies[:locale]&.to_sym
    return cookie_locale if cookie_locale && I18n.available_locales.include?(cookie_locale)

    # 2. Accept-Language header
    return unless request.env["HTTP_ACCEPT_LANGUAGE"]

    parsed = request.env["HTTP_ACCEPT_LANGUAGE"]
      .split(",")
      .map { |lang| lang.strip.split(";q=") }
      .map { |lang, q| [ lang, (q || 1).to_f ] }
      .sort_by { |_, q| -q }

    parsed.each do |lang, _|
      locale = lang.strip
      # Exact match (e.g., "zh-TW")
      sym = locale.to_sym
      return sym if I18n.available_locales.include?(sym)
      # Base language match (e.g., "zh" -> "zh-TW", "ja" -> :ja)
      base = locale.split("-").first
      match = I18n.available_locales.find { |l| l.to_s.start_with?(base) }
      return match if match
    end

    nil
  end
end
