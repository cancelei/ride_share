class UserMailer < ApplicationMailer
    default from: "admin@rideflow.live" # Use your Brevo verified email

    def welcome_email(user)
      @user = user
      mail(to: @user.email, subject: "Welcome to RideFlow")
    end

    def booking_confirmation(booking)
      @booking = booking
      @passenger = booking.passenger.user

      mail(
        to: @passenger.email,
        subject: "Booking Confirmation - RideFlow"
      )
    end

    def ride_accepted(booking)
      @booking = booking
      @passenger = booking.passenger.user
      @driver = booking.ride.driver.user

      mail(
        to: @passenger.email,
        subject: "Driver Assigned - Your RideFlow Ride"
      )
    end

    def driver_arrived(booking)
      @booking = booking
      @passenger = booking.passenger.user
      @driver = booking.ride.driver.user
      @security_code = booking.ride.security_code

      mail(
        to: @passenger.email,
        subject: "Your Driver Will Arrive Soon - RideFlow"
      )
    end

    def ride_completion_passenger(booking)
      @booking = booking
      @passenger = booking.passenger.user

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

    def ride_completion_driver(booking)
      @booking = booking
      @driver = booking.ride.driver.user

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

    def new_booking_notification(booking, driver, other_bookings = [])
      # Check if the booking still exists
      return unless booking && Booking.exists?(booking.id)
      
      @booking = booking
      @driver = driver
      @other_bookings = other_bookings.select { |b| Booking.exists?(b.id) }
      
      mail(
        to: @driver.email,
        subject: "New Ride Request Available - RideFlow"
      ) if @driver && User.exists?(@driver.id)
    rescue => e
      Rails.logger.error "Error preparing new booking notification email: #{e.message}"
    end
end
