namespace :email do
  desc "Test email delivery method"
  task test_delivery: :environment do
    puts "Current delivery method: #{ActionMailer::Base.delivery_method}"
    puts "USE_EMAIL_API env var: #{ENV['USE_EMAIL_API']}"
    
    # Use a valid email address for testing
    test_email = ENV['TEST_EMAIL'] || "webexo1894@apklamp.com"  # Replace with a real email
    
    # Create a test user if needed
    user = User.find_by(email: test_email) || User.first || User.create!(
      email: test_email,
      password: "password",
      first_name: "Test",
      last_name: "User"
    )
    
    puts "Sending test email to: #{user.email}"
    
    # Send a test email
    begin
      mail = UserMailer.welcome_email(user)
      puts "Mail object created, delivery method: #{mail.delivery_method}"
      
      # Force delivery method to :api for testing
      mail.delivery_method.delivery_method = :api if ENV['FORCE_API'] == 'true'
      
      result = mail.deliver_now
      puts "Email delivered: #{result.inspect}"
      puts "Success!"
    rescue => e
      puts "Error sending email: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
end 