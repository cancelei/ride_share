class RideNotificationService
  def self.notify_drivers(ride)
    Rails.logger.info "Starting driver notification process for ride #{ride.id}"

    # Find all users with driver profiles
    drivers = User.joins(:driver_profile)
                 .where(driver_profiles: { discarded_at: nil })
                 .where(discarded_at: nil)

    Rails.logger.info "Found #{drivers.count} active drivers to notify"

    drivers.each do |driver|
      Rails.logger.info "Sending notification to driver #{driver.id} (#{driver.email})"
      begin
        # Store the ride_id instead of the ride object to prevent serialization issues
        RideMailer.new_ride_notification(driver, ride.id).deliver_later
        Rails.logger.info "Successfully queued notification for driver #{driver.id}"
      rescue => e
        Rails.logger.error "Failed to send notification to driver #{driver.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end
  end
end
