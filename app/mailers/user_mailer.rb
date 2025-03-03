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
        subject: "Your Driver Has Arrived - RideFlow"
      )
    end

    def ride_completion_passenger(booking)
      @booking = booking
      @passenger = booking.passenger.user

      mail(
        to: @passenger.email,
        subject: "Ride Completed - Thank You for Using RideFlow"
      )
    end

    def ride_completion_driver(booking)
      @booking = booking
      @driver = booking.ride.driver.user

      mail(
        to: @driver.email,
        subject: "Ride Summary - RideFlow"
      )
    end
end
