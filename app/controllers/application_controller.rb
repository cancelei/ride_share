class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name, :phone_number, :country, :role ])
  end

    def after_sign_up_path_for(resource)
      puts resource.role
      puts resource.role
      puts resource.role
      puts resource.role
      case resource.role
      when "driver", 2
        new_driver_profile_path
      end
    end
end
