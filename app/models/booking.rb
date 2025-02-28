class Booking < ApplicationRecord
  include Discard::Model
  include RideStatusBroadcaster
  include PriceCalculator
  default_scope -> { kept }

  belongs_to :passenger, -> { with_discarded }, class_name: "PassengerProfile", foreign_key: :passenger_id
  belongs_to :ride, -> { with_discarded }, optional: true
  has_many :locations, -> { with_discarded }, dependent: :destroy
  has_one :pickup_location, -> { where(location_type: "pickup") }, class_name: "Location"
  has_one :dropoff_location, -> { where(location_type: "dropoff") }, class_name: "Location"

  before_create :set_status
  before_save :set_estimated_ride_price, if: :ride_id_changed?

  after_update :broadcast_status_update
  after_create :broadcast_status_update
  after_commit :broadcast_update
  after_commit :broadcast_to_drivers, on: :create
  after_commit :broadcast_cancellation, if: -> { saved_change_to_status? && status == "cancelled" }

  def set_estimated_ride_price
    return unless ride_id.present?

    total_distance = Booking.where(ride_id: ride_id)
                           .pluck(:distance_km)
                           .sum + (distance_km || 0)

    total_price = (3.5 + total_distance * 2).round(2)
    ride.update_column(:estimated_price, total_price)
  end

  enum :status, { pending: "pending", accepted: "accepted", in_progress: "in_progress", rejected: "rejected", completed: "completed", cancelled: "cancelled" }, prefix: true

  accepts_nested_attributes_for :locations

  scope :active, -> { where(status: [ "pending", "accepted", "in_progress" ]) }
  scope :pending, -> { where(status: "pending") }
  scope :past, -> { where(status: [ "completed" ]) }
  scope :cancelled, -> { where(status: "cancelled") }
  def pickup
    pickup_location&.address
  end

  def dropoff
    dropoff_location&.address
  end

  def calculate_distance_to_driver
    return nil unless ride&.driver&.user&.current_latitude && ride&.driver&.user&.current_longitude

    pickup_coords = Geocoder.coordinates(status_accepted? ? pickup : dropoff)
    return nil unless pickup_coords

    driver_coords = [ ride.driver.user.current_latitude, ride.driver.user.current_longitude ]

    distance = Geocoder::Calculations.distance_between(pickup_coords, driver_coords, units: :km)
    distance.round(1)
  end

  def calculate_eta_minutes
    return nil unless distance_to_pickup = calculate_distance_to_driver

    # Assuming average speed of 40 km/h in city traffic
    (distance_to_pickup * 1.5).round
  end

  private

  def set_status
    self.status = "pending"
  end

  def broadcast_update
    broadcast_to_passenger
    broadcast_to_driver if ride&.driver
  end

  def broadcast_to_passenger
    Turbo::StreamsChannel.broadcast_update_to(
      "user_#{passenger.user_id}_dashboard",
      target: "rides_content",
      partial: "dashboard/rides_content",
      locals: {
        my_bookings: passenger.bookings,
        user: passenger.user
      }
    )
  end

  def broadcast_to_driver
    return unless ride&.driver&.user_id

    Turbo::StreamsChannel.broadcast_update_to(
      "user_#{ride.driver.user_id}_dashboard",
      target: "rides_content",
      partial: "dashboard/rides_content",
      locals: {
        my_bookings: ride.bookings,
        user: ride.driver.user
      }
    )
  end

  def broadcast_to_drivers
    return unless status == "pending"

    pending_bookings = Booking.pending.includes(:passenger, :ride)

    User.role_driver.find_each do |driver|
      Turbo::StreamsChannel.broadcast_replace_to(
        "user_#{driver.id}_dashboard",
        target: "pending_bookings",
        partial: "dashboard/pending_bookings",
        locals: {
          pending_bookings: pending_bookings,
          current_user: driver
        }
      )
    end
  end

  def broadcast_cancellation
    broadcast_to_all_drivers
    broadcast_to_assigned_driver if ride&.driver
  end

  def broadcast_to_all_drivers
    pending_bookings = Booking.pending.includes(:passenger, :ride)

    User.role_driver.find_each do |driver|
      Turbo::StreamsChannel.broadcast_replace_to(
        "user_#{driver.id}_dashboard",
        target: "pending_bookings",
        partial: "dashboard/pending_bookings",
        locals: {
          pending_bookings: pending_bookings,
          current_user: driver
        }
      )
    end
  end

  def broadcast_to_assigned_driver
    Turbo::StreamsChannel.broadcast_replace_to(
      "user_#{ride.driver.user_id}_dashboard",
      target: "rides_content",
      partial: "dashboard/rides_content",
      locals: {
        my_bookings: ride.bookings,
        active_rides: ride.driver.rides.active,
        pending_bookings: Booking.pending,
        past_rides: ride.driver.rides.past
      }
    )
  end
end
