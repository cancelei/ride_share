module DriverLocationBroadcaster
  extend ActiveSupport::Concern

  def broadcast_location
    return unless driver_profile.present?

    Ride.pending.each do |ride|
      Turbo::StreamsChannel.broadcast_update_to(
        "ride_#{ride.id}",
        target: "ride-#{ride.id}-distance",
        partial: "dashboard/ride_distance",
        locals: { ride: ride, current_user: self }
      )
    end
  rescue => e
    Rails.logger.error "Failed to broadcast location: #{e.message}"
  end
end
