class LocationTrackingService
  def initialize(booking)
    @booking = booking
  end

  def calculate_driver_distance
    return nil unless driver_location && pickup_location

    driver_location.distance_to(pickup_location)
  end

  def calculate_eta
    distance = calculate_driver_distance
    return nil unless distance

    # Assuming average speed of 40 km/h in city traffic
    (distance * 1.5).round
  end

  def update_driver_location(latitude, longitude, address = nil)
    return false unless @booking.ride&.driver&.user

    driver = @booking.ride.driver.user

    # Update driver's current location
    driver.update(
      current_latitude: latitude,
      current_longitude: longitude,
      current_address: address,
      location_updated_at: Time.current
    )

    # Broadcast updated location to all relevant clients
    broadcast_location_update

    true
  end

  def broadcast_location_update
    return unless @booking.ride&.driver&.user_id

    distance = calculate_driver_distance
    eta = calculate_eta

    # Broadcast to passenger
    Turbo::StreamsChannel.broadcast_update_to(
      "user_#{@booking.passenger.user_id}_location_updates",
      target: "booking-#{@booking.id}-distance",
      partial: "dashboard/location_tracking_content",
      locals: {
        booking: @booking,
        distance: distance,
        eta: eta
      }
    )

    # Broadcast to driver
    Turbo::StreamsChannel.broadcast_update_to(
      "user_#{@booking.ride.driver.user_id}_location_updates",
      target: "booking-#{@booking.id}-distance",
      partial: "dashboard/location_tracking_content",
      locals: {
        booking: @booking,
        distance: distance,
        eta: eta
      }
    )
  end

  private

  def driver_location
    driver = @booking.ride&.driver&.user
    return nil unless driver&.current_latitude && driver&.current_longitude

    @driver_location ||= Location.new(
      latitude: driver.current_latitude,
      longitude: driver.current_longitude,
      address: driver.current_address
    )
  end

  def pickup_location
    if @booking.status_accepted?
      @booking.pickup_location
    else
      @booking.dropoff_location
    end
  end
end
