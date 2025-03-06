require "api_delivery_method"

ActionMailer::Base.add_delivery_method :api, ApiDeliveryMethod

# Set API as the default delivery method
Rails.application.config.action_mailer.delivery_method = :api

# Remove any SMTP configuration
Rails.application.config.action_mailer.smtp_settings = nil

# Add debug output to verify initialization
Rails.logger.debug "API delivery method registered and set as default: #{ActionMailer::Base.delivery_methods[:api].inspect}"
