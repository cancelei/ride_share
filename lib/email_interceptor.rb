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

  def self.delivering_email(message)
    # Log email details
    Rails.logger.debug "=" * 50
    Rails.logger.debug "DELIVERING EMAIL"
    Rails.logger.debug "From: #{message.from}"
    Rails.logger.debug "To: #{message.to}"
    Rails.logger.debug "Subject: #{message.subject}"
    Rails.logger.debug "Body: #{message.body}"
    Rails.logger.debug "=" * 50

    # In staging, redirect all emails to a safe email address if specified
    if Rails.env.staging? && ENV["STAGING_EMAIL_RECIPIENT"].present?
      message.to = [ ENV["STAGING_EMAIL_RECIPIENT"] ]
      message.subject = "[STAGING] #{message.subject}"
    end

    # Add environment tag to subject
    unless Rails.env.production?
      message.subject = "[#{Rails.env.upcase}] #{message.subject}"
    end
  end
end
