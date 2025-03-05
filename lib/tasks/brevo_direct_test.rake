namespace :brevo do
  desc "Test Brevo API directly"
  task direct_test: :environment do
    require 'sib-api-v3-sdk'
    
    puts "Testing Brevo API directly..."
    
    # Configure API key
    api_key = ENV['BREVO_API_KEY']
    if api_key.blank?
      puts "ERROR: BREVO_API_KEY environment variable is not set"
      exit 1
    end
    
    puts "Using API key: #{api_key[0..3]}...#{api_key[-4..-1]}"
    
    SibApiV3Sdk.configure do |config|
      config.api_key['api-key'] = api_key
    end
    
    # Create API instance
    api_instance = SibApiV3Sdk::TransactionalEmailsApi.new
    
    # Get test email
    test_email = ENV['TEST_EMAIL'] || "webexo1894@apklamp.com"  # Replace with a real email
    puts "Sending test email to: #{test_email}"
    
    # Create sender
    sender = SibApiV3Sdk::SendSmtpEmailSender.new(
      email: "admin@rideflow.live",
      name: "RideFlow Test"
    )
    
    # Create recipient
    to = [
      SibApiV3Sdk::SendSmtpEmailTo.new(
        email: test_email,
        name: "Test User"
      )
    ]
    
    # Create email content
    html_content = "<html><body><h1>Direct API Test</h1><p>This is a test email sent directly via the Brevo API.</p></body></html>"
    text_content = "Direct API Test\n\nThis is a test email sent directly via the Brevo API."
    
    # Create email object - FIXED PARAMETER NAMES
    email = SibApiV3Sdk::SendSmtpEmail.new(
      sender: sender,
      to: to,
      subject: "Brevo Direct API Test",
      htmlContent: html_content,  # Changed from html_content to htmlContent
      textContent: text_content   # Changed from text_content to textContent
    )
    
    begin
      # Send the email
      result = api_instance.send_transac_email(email)
      puts "SUCCESS: Email sent via API"
      puts "Message ID: #{result.message_id}"
    rescue => e
      puts "ERROR: #{e.class.name}: #{e.message}"
      puts "Response body: #{e.response_body}" if e.respond_to?(:response_body) && e.response_body
      puts e.backtrace.join("\n")
    end
  end
end 