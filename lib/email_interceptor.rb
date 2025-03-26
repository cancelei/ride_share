class EmailInterceptor
  def initialize(app)
    @app = app
  end

  def call(env)
    # Only intercept ActionMailer requests
    if env["action_dispatch.parameter_filter"]
      ActionMailer::Base.set_callback(:process, :after) do |mailer|
        Rails.logger.info "========== EMAIL WOULD BE SENT =========="
        Rails.logger.info "From: #{mailer.class}"
        Rails.logger.info "To: #{mailer.message.to}"
        Rails.logger.info "Subject: #{mailer.message.subject}"
        Rails.logger.info "Method: #{mailer.action_name}"
        Rails.logger.info "========================================"
      end
    end

    @app.call(env)
  end
end
