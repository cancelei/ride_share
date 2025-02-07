module DriverLocationBroadcaster
  extend ActiveSupport::Concern

  def broadcast_location
    return unless driver_profile.present?

    Booking.pending.each do |booking|
      Turbo::StreamsChannel.broadcast_update_to(
        "booking_#{booking.id}",
        target: "booking-#{booking.id}-distance",
        partial: "dashboard/booking_distance",
        locals: { booking: booking, current_user: self }
      )
    end
  rescue => e
    Rails.logger.error "Failed to broadcast location: #{e.message}"
  end
end
