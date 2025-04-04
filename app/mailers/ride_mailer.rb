class RideMailer < ApplicationMailer
  default from: "notifications@example.com"

  def new_ride_notification(driver, ride)
    @driver = driver
    @ride = ride
    @passenger = @ride.passenger.user

    mail(
      to: @driver.email,
      subject: "New Ride Available: #{@ride.pickup_address} to #{@ride.dropoff_address}"
    )
  end
end
