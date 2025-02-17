module RideStatusBroadcaster
  extend ActiveSupport::Concern

  def broadcast_status_update
    # For passenger
    if @passenger.present?
      Turbo::StreamsChannel.broadcast_update_to(
        "user_#{passenger.user_id}_dashboard",
        target: "rides_content",
        partial: "dashboard/rides_content",
        locals: {
          my_bookings: passenger.bookings,
          params: { type: "active" }  # Default to active tab
        }
      )
    end

    # For driver
    if @ride&.driver.present?
      Turbo::StreamsChannel.broadcast_update_to(
        "user_#{ride.driver.user_id}_dashboard",
        target: "rides_content",
        partial: "dashboard/rides_content",
        locals: {
          my_bookings: ride.bookings,
          params: { type: "active" },  # Default to active tab
          active_rides: ride.driver.rides.active,
          pending_bookings: Booking.pending,
          past_rides: ride.driver.rides.past
        }
      )
    end
  end
end
