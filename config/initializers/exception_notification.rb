Rails.application.config.middleware.use ExceptionNotification::Rack,
  email: {
    email_prefix: "[RideFlow Error] ",
    sender_address: %("notifier" <admin@rideflow.live>),
    exception_recipients: %w[admin@rideflow.live]
  }
