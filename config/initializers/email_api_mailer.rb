require 'api_delivery_method'

ActionMailer::Base.add_delivery_method :api, ApiDeliveryMethod

# Add debug output to verify initialization
Rails.logger.debug "API delivery method registered: #{ActionMailer::Base.delivery_methods[:api].inspect}" 