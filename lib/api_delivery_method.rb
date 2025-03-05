class ApiDeliveryMethod
  def initialize(options = {})
    # Store any configuration options
    Rails.logger.debug "ApiDeliveryMethod initialized with options: #{options.inspect}"
  end

  def deliver!(mail)
    Rails.logger.debug "ApiDeliveryMethod.deliver! called for email to: #{mail.to.join(', ')}"
    Rails.logger.debug "Subject: #{mail.subject}"
    
    begin
      result = EmailApiService.send_email(mail)
      Rails.logger.debug "Email API service result: #{result.inspect}"
      result
    rescue => e
      Rails.logger.error "Error in ApiDeliveryMethod.deliver!: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end
end 