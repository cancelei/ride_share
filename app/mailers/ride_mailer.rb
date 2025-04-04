class RideMailer < ApplicationMailer
  default from: ENV.fetch("MAILER_FROM", "no-reply@rideflow.live")

  def new_ride_notification(driver, ride)
    Rails.logger.info "Preparing new ride notification email for driver #{driver.id}"

    @driver = driver
    @ride = ride
    @passenger = @ride.passenger&.user

    Rails.logger.info "Sending email to #{@driver.email} about ride #{@ride.id}"

    mail(
      to: @driver.email,
      subject: "New Ride Available: #{@ride.pickup_address} to #{@ride.dropoff_address}",
      template_path: "ride_mailer",
      template_name: "new_ride_notification"
    )
  end
end
