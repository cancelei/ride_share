class UserMailer < ApplicationMailer
    default from: "admin@rideflow.live" # Use your Brevo verified email

    def welcome_email(user)
      @user = user
      mail(to: @user.email, subject: "Welcome to RideFlow")
    end
end
