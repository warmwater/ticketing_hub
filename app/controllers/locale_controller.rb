class LocaleController < ApplicationController
  def update
    locale = params[:locale]&.to_sym
    if locale && I18n.available_locales.include?(locale)
      cookies[:locale] = { value: locale.to_s, expires: 1.year.from_now }
    end
    redirect_back(fallback_location: root_path)
  end
end
