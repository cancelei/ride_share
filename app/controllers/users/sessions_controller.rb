class Users::SessionsController < Devise::SessionsController
  respond_to :html, :turbo_stream

  # Prevent CSRF issues with Turbo
  skip_before_action :verify_authenticity_token, only: :create
  prepend_before_action :allow_params_authentication!, only: :create

  def new
    self.resource = resource_class.new
    render :new
  end

  def create
    self.resource = warden.authenticate!(auth_options)
    sign_in(resource_name, resource)

    respond_to do |format|
      if current_user
        format.turbo_stream { redirect_to after_sign_in_path_for(resource), notice: t("devise.sessions.signed_in") }
        format.html { redirect_to after_sign_in_path_for(resource), notice: t("devise.sessions.signed_in") }
      else
        format.turbo_stream { redirect_to new_user_session_path, alert: t("devise.failure.invalid", authentication_keys: "email") }
        format.html { redirect_to new_user_session_path, alert: t("devise.failure.invalid", authentication_keys: "email") }
      end
    end
  rescue Warden::AuthenticationError
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "login_form",
          partial: "devise/sessions/form",
          locals: { resource: resource, error: t("devise.failure.invalid", authentication_keys: "email") }
        )
      }
      format.html { redirect_to new_user_session_path, alert: t("devise.failure.invalid", authentication_keys: "email") }
    end
  end

  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    flash[:notice] = t("devise.sessions.signed_out")

    respond_to do |format|
      format.turbo_stream { redirect_to new_user_session_path, status: :see_other }
      format.html { redirect_to new_user_session_path, status: :see_other }
    end
  end

  protected

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end
