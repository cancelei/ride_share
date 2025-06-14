class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern do |config|
    # Customize the response for unsupported browsers
    config.response = -> { render file: "public/406-unsupported-browser.html", layout: false }
  end

  before_action :authenticate_user!

  before_action :configure_permitted_parameters, if: :devise_controller?

  protect_from_forgery with: :exception
  before_action :store_user_location!, if: :storable_location?

  before_action :set_current_user_for_views

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name, :phone_number, :country, :role, :timezone ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :phone_number, :country, :role, :timezone ])
  end

  private

  def storable_location?
    request.get? &&
    is_navigational_format? &&
    !devise_controller? &&
    !request.xhr? &&
    !turbo_frame_request?
  end

  def store_user_location!
    store_location_for(:user, request.fullpath)
  end

  def set_current_user_for_views
    @current_user = current_user if defined?(current_user)
  end
end
