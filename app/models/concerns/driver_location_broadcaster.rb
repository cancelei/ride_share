module DriverLocationBroadcaster
  extend ActiveSupport::Concern

  def broadcast_location(latitude, longitude)
    pending_bookings = Booking.pending
    pending_bookings.each do |booking|
      Turbo::StreamsChannel.broadcast_replace_to(
        "driver_location",
        target: "booking-#{booking.id}-distance",
        partial: "dashboard/booking_distance",
        locals: {
          booking: booking,
          current_coordinates: { latitude: latitude, longitude: longitude }
        }
      )
    end
  end
end
