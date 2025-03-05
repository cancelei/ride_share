class EmailApiService
  class << self
    def configure
      SibApiV3Sdk.configure do |config|
        config.api_key['api-key'] = ENV['BREVO_API_KEY']
      end
    end

    def send_email(mail)
      configure

      # Debug the mail object
      Rails.logger.debug "Sending email via API to: #{mail.to.join(', ')}"
      Rails.logger.debug "Subject: #{mail.subject}"
      Rails.logger.debug "From: #{mail.from.first}"
      
      # Create API instance
      api_instance = SibApiV3Sdk::TransactionalEmailsApi.new
      
      # Validate email addresses
      recipients = mail.to || []
      valid_recipients = recipients.select { |email| valid_email?(email) }
      
      if valid_recipients.empty?
        Rails.logger.warn "No valid recipients found for email. Original recipients: #{recipients.join(', ')}"
        return false if Rails.env.development? || Rails.env.test?
      end
      
      # Create sender
      sender = SibApiV3Sdk::SendSmtpEmailSender.new(
        email: mail.from.first,
        name: mail.header['from']&.display_names&.first || 'RideFlow'
      )
      
      # Create recipients with validation
      to = valid_recipients.map do |email|
        SibApiV3Sdk::SendSmtpEmailTo.new(
          email: email,
          name: mail.header['to']&.display_names&.first || email.split('@').first
        )
      end
      
      # Extract HTML and text content with improved logic
      html_content = nil
      text_content = nil
      
      # Try to get HTML content
      if mail.html_part&.body.present?
        html_content = mail.html_part.body.to_s
        Rails.logger.debug "Found HTML part: #{html_content.truncate(100)}"
      elsif mail.content_type =~ /text\/html/
        html_content = mail.body.to_s
        Rails.logger.debug "Found HTML body: #{html_content.truncate(100)}"
      elsif mail.body.present?
        html_content = mail.body.to_s
        Rails.logger.debug "Using default body as HTML: #{html_content.truncate(100)}"
      end
      
      # Try to get text content
      if mail.text_part&.body.present?
        text_content = mail.text_part.body.to_s
        Rails.logger.debug "Found text part: #{text_content.truncate(100)}"
      elsif mail.content_type =~ /text\/plain/
        text_content = mail.body.to_s
        Rails.logger.debug "Found text body: #{text_content.truncate(100)}"
      elsif html_content.present?
        text_content = ActionController::Base.helpers.strip_tags(html_content)
        Rails.logger.debug "Generated text from HTML: #{text_content.truncate(100)}"
      end
      
      # Ensure we have at least one content type
      if html_content.blank? && text_content.blank?
        # If no content found, create a simple fallback content
        html_content = "<html><body><p>Email content not available.</p></body></html>"
        text_content = "Email content not available."
        Rails.logger.warn "No content found in email. Using fallback content."
      end
      
      # Ensure content is properly encoded
      html_content = html_content.force_encoding('UTF-8') if html_content.present?
      text_content = text_content.force_encoding('UTF-8') if text_content.present?
      
      # Create email object with minimal required parameters - FIXED PARAMETER NAMES
      email_params = {
        sender: sender,
        to: to,
        subject: mail.subject || "No Subject"
      }
      
      # Only add content that's present and non-empty - FIXED PARAMETER NAMES
      email_params[:htmlContent] = html_content if html_content.present?
      email_params[:textContent] = text_content if text_content.present?
      
      # Debug the email parameters
      Rails.logger.debug "Email params: #{email_params.except(:htmlContent, :textContent).inspect}"
      Rails.logger.debug "HTML content present: #{html_content.present?}"
      Rails.logger.debug "Text content present: #{text_content.present?}"
      
      # Create the email object
      begin
        email = SibApiV3Sdk::SendSmtpEmail.new(email_params)
      rescue => e
        Rails.logger.error "Error creating SendSmtpEmail object: #{e.message}"
        raise e
      end
      
      # Skip sending if no valid recipients in development/test
      return true if to.empty? && (Rails.env.development? || Rails.env.test?)
      
      # Send email with better error handling
      begin
        # Send the email
        result = api_instance.send_transac_email(email)
        Rails.logger.info "Email sent via API: #{result.inspect}"
        result
      rescue SibApiV3Sdk::ApiError => e
        Rails.logger.error "API email delivery failed: #{e.message}"
        Rails.logger.error "Response code: #{e.code}" if e.respond_to?(:code)
        Rails.logger.error "Response body: #{e.response_body}" if e.response_body
        
        # Try to parse the response body for more details
        if e.response_body.present?
          begin
            error_details = JSON.parse(e.response_body)
            Rails.logger.error "Error details: #{error_details.inspect}"
          rescue JSON::ParserError
            Rails.logger.error "Could not parse error response as JSON"
          end
        end
        
        Rails.logger.error e.backtrace.join("\n")
        
        # Re-raise the error to be handled by the application
        raise e
      end
    end

    def create_or_update_contact(user)
      configure
      
      api_instance = SibApiV3Sdk::ContactsApi.new
      
      # Create contact
      create_contact = SibApiV3Sdk::CreateContact.new(
        email: user.email,
        attributes: {
          FIRSTNAME: user.first_name,
          LASTNAME: user.last_name,
          PHONE: user.phone_number,
          ROLE: user.role
        }
      )
      
      begin
        api_instance.create_contact(create_contact)
        Rails.logger.info "Contact created/updated in email service: #{user.email}"
      rescue SibApiV3Sdk::ApiError => e
        Rails.logger.error "Error creating/updating contact in email service: #{e.message}"
      end
    end

    # Helper method to validate email addresses
    def valid_email?(email)
      # Basic email validation
      email_regex = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
      
      # Check format
      valid_format = email_regex.match?(email.to_s.downcase)
      
      # In development, allow all emails that match the format
      if Rails.env.development? || Rails.env.test?
        return valid_format
      else
        # In production, also check for common test domains
        not_test_domain = !email.to_s.downcase.end_with?('.test', '.example', '.invalid', '.localhost', '.oasm')
        return valid_format && not_test_domain
      end
    end
  end
end 