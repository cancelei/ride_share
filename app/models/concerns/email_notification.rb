module EmailNotification
  extend ActiveSupport::Concern
  # Helper to deliver emails in the background if in production/staging
  # or just log in development
  def deliver_email(mailer_class, method_name, *args)
      # Send in background using solid_queue
      mailer_class.send(method_name, *args).deliver_later(queue: :mailers)
  end
end
