module Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :configure_sign_up_params, only: [ :create ]

    protected

    def configure_sign_up_params
      devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :phone, :role ])
    end

    def after_sign_up_path_for(resource)
      case resource.role
      when "admin" then admin_root_path
      when "organizer" then organizer_root_path
      else root_path
      end
    end
  end
end
