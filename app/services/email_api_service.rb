class EmailApiService
  class << self
    def configure
      api_key = ENV["BREVO_API_KEY"] || Rails.application.credentials.dig(:brevo, :api_key)

      if api_key.blank?
        error_msg = "BREVO_API_KEY is not set! Please configure the API key in your environment variables or credentials."
        Rails.logger.error error_msg
        raise StandardError, error_msg
      end

      Rails.logger.info "Configuring Brevo API with key: #{api_key[0..3]}...#{api_key[-4..-1]}"

      # Configure the API key directly on the configuration
      SibApiV3Sdk.configure do |config|
        config.api_key["api-key"] = api_key
      end

      true
    end

    def send_email(params)
      Rails.logger.info "Sending email via API with params: #{params.inspect}"

      # Configure API key before each request
      configure

      # Initialize Brevo API client
      api_instance = SibApiV3Sdk::TransactionalEmailsApi.new

      # Extract parameters safely
      to_email = params[:to].to_s
      subject = params[:subject].to_s
      html_content = params[:html_content].to_s
      text_content = params[:text_content].to_s
      sender_email = params[:sender][:email].to_s rescue "noreply@rideflow.com"
      sender_name = params[:sender][:name].to_s rescue "RideFlow"

      # Validate required parameters
      if to_email.blank?
        error_msg = "Missing recipient email address"
        Rails.logger.error error_msg
        raise ArgumentError, error_msg
      end

      if html_content.blank?
        error_msg = "Missing HTML content for email"
        Rails.logger.error error_msg
        raise ArgumentError, error_msg
      end

      Rails.logger.info "Preparing to send email to: #{to_email}"

      # Create sender
      sender = SibApiV3Sdk::SendSmtpEmailSender.new(
        email: sender_email,
        name: sender_name
      )

      # Create recipient
      to = [ { email: to_email } ]

      # Create email object
      email = SibApiV3Sdk::SendSmtpEmail.new(
        sender: sender,
        to: to,
        subject: subject,
        htmlContent: html_content,  # Note: using camelCase as required by the API
        textContent: text_content   # Note: using camelCase as required by the API
      )

      # Send email
      begin
        result = api_instance.send_transac_email(email)
        Rails.logger.info "Email sent successfully: #{result}"
        result
      rescue SibApiV3Sdk::ApiError => e
        Rails.logger.error "API error when sending email: #{e.response_body}"
        raise e
      rescue => e
        Rails.logger.error "General error when sending email: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
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
        valid_format
      else
        # In production, also check for common test domains
        not_test_domain = !email.to_s.downcase.end_with?(".test", ".example", ".invalid", ".localhost", ".oasm")
        valid_format && not_test_domain
      end
    end
  end
end
