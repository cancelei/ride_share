module EmailNotification
  extend ActiveSupport::Concern

  class_methods do
    # Define class methods for configuring email notifications
    def notify_by_email(options = {})
      after_create options[:on] || :send_creation_email if options[:after_create]
      after_update options[:on] || :send_update_email if options[:after_update]
      after_save options[:on] || :send_save_email if options[:after_save]
      after_destroy options[:on] || :send_destroy_email if options[:after_destroy]
    end
  end

  # Helper to deliver emails in the background if in production/staging
  # or just log in development
  def deliver_email(mailer_class, method_name, *args)
    if Rails.env.production? || Rails.env.staging?
      # Send in background using solid_queue
      mailer_class.send(method_name, *args).deliver_later(queue: :mailers)
    else
      # Just log in development
      Rails.logger.info "===== DEVELOPMENT EMAIL NOTIFICATION ====="
      Rails.logger.info "Would deliver email: #{mailer_class}.#{method_name}"
      Rails.logger.info "With args: #{args.inspect}"
      Rails.logger.info "========================================"
    end
  end
end
