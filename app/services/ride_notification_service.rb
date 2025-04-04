class RideNotificationService
  def self.notify_drivers(ride)
    # Find all users with driver profiles
    drivers = User.joins(:driver_profile)
                 .where(driver_profiles: { discarded_at: nil })
                 .where(discarded_at: nil)

    drivers.each do |driver|
      # Send email to each driver
      RideMailer.new_ride_notification(driver, ride).deliver_later
    end
  end
end
