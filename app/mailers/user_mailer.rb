class UserMailer < ApplicationMailer
    default from: "admin@rideflow.live" # Use your Brevo verified email

    def welcome_email(user)
      @user = user
      mail(to: @user.email, subject: "Welcome to RideFlow")
    end

    def ride_accepted(ride)
      @ride = ride
      @passenger = ride.passenger.user
      @driver = ride.driver.user

      mail(
        to: @passenger.email,
        subject: "Driver Assigned - Your RideFlow Ride"
      )
    end

    def driver_arrived(ride)
      @ride = ride
      @passenger = ride.passenger.user
      @driver = ride.driver.user
      @security_code = ride.security_code

      mail(
        to: @passenger.email,
        subject: "Your Driver Will Arrive Soon - RideFlow"
      )
    end

    def ride_completion_passenger(ride)
      @ride = ride
      @passenger = ride.passenger.user

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

    def ride_confirmation(ride)
      @ride = ride
      @passenger = ride.passenger.user

      mail(
        to: @passenger.email,
        subject: "Ride Confirmation - RideFlow"
      )
    end
end
