module RideStatusBroadcaster
  extend ActiveSupport::Concern

  def broadcast_status_update
    Rails.logger.debug "DEBUG: RideStatusBroadcaster#broadcast_status_update called for ride #{id}"
    Rails.logger.debug "DEBUG: Ride status: #{status}"
    Rails.logger.debug "DEBUG: Passenger present? #{passenger.present?}"
    Rails.logger.debug "DEBUG: Driver present? #{driver.present?}"

    # For passenger
    if passenger.present?
      Rails.logger.debug "DEBUG: Broadcasting to passenger: #{passenger.user_id}"
      passenger_user = passenger.user

      Turbo::StreamsChannel.broadcast_update_to(
        "user_#{passenger.user_id}_dashboard",
        target: "rides_content",
        partial: "dashboard/rides_content",
        locals: {
          my_rides: Ride.where(passenger: passenger).order(scheduled_time: :desc),
          params: {
            type: [ :completed, :cancelled ].include?(status.to_sym) ? "history" : "active"
          },
          user: passenger_user
        }
      )

      # Direct broadcast to the specific ride card when status changes
      if [ "accepted", "in_progress", "completed" ].include?(status)
        Rails.logger.debug "DEBUG: Broadcasting #{status} status to passenger's ride card"

        Turbo::StreamsChannel.broadcast_replace_to(
          "user_#{passenger.user_id}_rides",
          target: "ride_#{id}",
          partial: "rides/ride_card",
          locals: {
            ride: self,
            current_user: passenger_user
          }
        )
      end
    end

    # For driver
    if driver.present?
      Rails.logger.debug "DEBUG: Broadcasting to driver: #{driver.user_id}"
      driver_user = driver.user

      Turbo::StreamsChannel.broadcast_update_to(
        "user_#{driver.user_id}_dashboard",
        target: "rides_content",
        partial: "dashboard/rides_content",
        locals: {
          my_rides: Ride.where(driver: driver).order(scheduled_time: :desc),
          params: {
            type: [ :completed, :cancelled ].include?(status.to_sym) ? "history" : "active",
            pending_rides: Ride.pending,
            past_rides: driver.rides.historical_rides
          },
          user: driver_user
        }
      )

      # Direct broadcast to the specific ride card when status changes
      if [ "accepted", "in_progress", "completed" ].include?(status)
        Rails.logger.debug "DEBUG: Broadcasting #{status} status to driver's ride card"

        Turbo::StreamsChannel.broadcast_replace_to(
          "user_#{driver.user_id}_rides",
          target: "ride_#{id}",
          partial: "rides/ride_card",
          locals: {
            ride: self,
            current_user: driver_user
          }
        )
      end
    end
  end
end
