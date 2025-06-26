class MigrateRideStatuses < ActiveRecord::Migration[8.0]
  def up
    Ride.all.includes(driver: :user, passenger: :user).each do |ride|
      # Create a new RideStatus for each ride with the current status
      RideStatus.create!(
        status: ride.status || "pending",
        ride: ride,
        user: ride.passenger.user
      )

      RideStatus.create!(
        status: ride.status || "pending",
        ride: ride,
        user: ride.driver.user
      ) if ride.driver.present?
    end
  end

  def down
    RideStatus.includes(ride: { passenger: :user, driver: :user }).find_each do |ride_status|
      # Find the ride associated with the RideStatus
      ride = ride_status.ride

      # Update the ride's status based on the RideStatus
      if ride_status.user == ride.passenger.user
        ride.update(status: ride_status.status)
      elsif ride_status.user == ride.driver.user
        # If the user is the driver, we can skip updating the status
        # as we only want to set it once for the passenger.
        next
      end

      # Destroy the RideStatus after updating the ride
      ride_status.destroy
    end
  end
end
