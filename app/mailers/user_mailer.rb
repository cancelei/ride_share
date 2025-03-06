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

    def new_booking_notification(driver, booking, pending_bookings)
      @driver = driver
      @booking = booking
      @pending_bookings = pending_bookings

      mail(
        to: @driver.email,
        subject: "New Ride Request Available - RideFlow"
      )
    end

    def send_notification_to_drivers
      # Get all drivers
      drivers = User.role_driver.includes(:driver_profile)

      Rails.logger.info "Found #{drivers.count} drivers to notify"

      # Get up to 5 other pending bookings (excluding this one)
      other_pending_bookings = Booking.pending
                                     .where.not(id: self.id)
                                     .includes(passenger: :user)
                                     .order(created_at: :desc)
                                     .limit(5)

      Rails.logger.info "Found #{other_pending_bookings.count} other pending bookings"

      # Send email to each driver
      drivers.find_each do |driver|
        # Only send to drivers with vehicles
        has_vehicles = driver.driver_profile&.vehicles&.exists?
        Rails.logger.info "Driver #{driver.id} (#{driver.email}) has vehicles: #{has_vehicles}"

        if has_vehicles
          # Use deliver_now in development for immediate delivery
          delivery_method = Rails.env.development? ? :deliver_now : :deliver_later
          UserMailer.new_booking_notification(driver, self, other_pending_bookings).send(delivery_method)
          Rails.logger.info "New booking notification email queued for delivery to driver: #{driver.email}"
        else
          Rails.logger.info "Skipping email to driver #{driver.email} - no vehicles"
        end
      end
    rescue => e
      Rails.logger.error "Failed to send driver notification emails: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
end
