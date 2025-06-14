module EmailNotification
  extend ActiveSupport::Concern
  # Helper to deliver emails in the background if in production/staging
  # or just log in development
  def deliver_email(mailer_class, method_name, *args)
    begin
      # Send in background using solid_queue
      Rails.logger.info "Queuing #{mailer_class}##{method_name} email with args: #{args.map(&:class).join(', ')}"
      mailer_class.send(method_name, *args).deliver_later(queue: :mailers)
    rescue => e
      Rails.logger.error "Error queuing email #{mailer_class}##{method_name}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      # Don't re-raise to prevent cascade failures
    end
  end
end
