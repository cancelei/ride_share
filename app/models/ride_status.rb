class RideStatus < ApplicationRecord
  enum :status, {
    pending: "pending",
    accepted: "accepted",
    waiting_for_passenger_boarding: "waiting_for_passenger_boarding",
    in_progress: "in_progress",
    rating_required: "rating_required",
    completed: "completed",
    cancelled: "cancelled"
  }

  after_commit :broadcast_ride_status, :handle_status_change_notifications, if: :saved_change_to_status?

  private

  def broadcast_ride_status
    Rails.logger.debug "DEBUG: Ride status: #{status}"
    Rails.logger.debug "DEBUG: Status changed from #{status_before_last_save} to #{status}"

    # Broadcast to the passenger
    if ride.passenger == user.passenger_profile
      Rails.logger.debug "DEBUG: Broadcasting to passenger: #{user_id}"
      broadcast_ride_card_to_user if status == "accepted" || status == "waiting_for_passenger_boarding" || status == "in_progress"
    end

    # Broadcast to the driver
    if ride.driver == user.driver_profile
      Rails.logger.debug "DEBUG: Broadcasting to driver: #{user_id}"
      broadcast_ride_card_to_user if status == "accepted" || status == "waiting_for_passenger_boarding" || status == "in_progress"
    end
  end

  def broadcast_ride_card_to_user
    Turbo::StreamsChannel.broadcast_replace_to(
      "user_#{user.id}_rides",
      target: "ride_#{ride.id}",
      partial: "rides/ride_card",
      locals: {
        ride: ride,
        current_user: user
      }
    )
  end
end
