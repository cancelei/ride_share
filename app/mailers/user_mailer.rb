class UserMailer < ApplicationMailer
    default from: "admin@rideflow.live" # Use your Brevo verified email

    # Helper method to determine the correct host based on environment
    def self.mailer_url
      case Rails.env
      when "production"
        "https://rideflow.live"
      when "staging"
        "https://staging.rideflow.live"
      else
        "http://localhost:3000"
      end
    end

    def welcome_email(user)
      @user = user
      @url = UserMailer.mailer_url
      mail(to: @user.email, subject: "Welcome to RideFlow")
    end

    def ride_accepted(ride)
      @ride = ride
      @passenger = ride.passenger.user
      @driver = ride.driver.user
      @url = UserMailer.mailer_url

      mail(
        to: @passenger.email,
        subject: "Driver Assigned to your Ride via RideFlow"
      )
    end

    def driver_arrived(ride)
      @ride = ride
      @passenger = ride.passenger.user
      @driver = ride.driver.user
      @security_code = ride.security_code
      @url = UserMailer.mailer_url

      mail(
        to: @passenger.email,
        subject: "Your Driver Arrived via RideFlow"
      )
    end

    def ride_completion_passenger(ride)
      @ride = ride
      @passenger = ride.passenger.user
      @url = UserMailer.mailer_url

      Rails.logger.info "Preparing passenger completion email for #{@passenger.email}"

      begin
        mail(
          to: @passenger.email,
          subject: "Ride Completed - Thank You for Using RideFlow"
        )
        Rails.logger.info "Passenger completion email prepared successfully"
      rescue => e
        Rails.logger.error "Error preparing passenger completion email: #{e.message}"
        raise e
      end
    end

    def ride_completion_driver(ride)
      @ride = ride
      @driver = ride.driver.user
      @url = UserMailer.mailer_url

      Rails.logger.info "Preparing driver completion email for #{@driver.email}"

      begin
        mail(
          to: @driver.email,
          subject: "Ride Summary - RideFlow"
        )
        Rails.logger.info "Driver completion email prepared successfully"
      rescue => e
        Rails.logger.error "Error preparing driver completion email: #{e.message}"
        raise e
      end
    end

    def ride_in_progress(ride)
      @ride = ride
      @passenger = ride.passenger.user
      @driver = ride.driver.user
      @url = UserMailer.mailer_url

      mail(
        to: @passenger.email,
        subject: "Your Ride Has Started via RideFlow"
      )
    end

    def ride_confirmation(ride)
      @ride = ride
      @passenger = ride.passenger.user
      @url = UserMailer.mailer_url

      mail(
        to: @passenger.email,
        subject: "Confirmed Ride Request via RideFlow"
      )
    end
end
