class Booking < ApplicationRecord
  include Discard::Model
  default_scope -> { kept }

  belongs_to :passenger, -> { with_discarded }, class_name: "PassengerProfile", foreign_key: :passenger_id
  belongs_to :ride, -> { with_discarded }, optional: true
  has_many :locations, -> { with_discarded }, dependent: :destroy
  has_one :pickup_location, -> { where(location_type: "pickup") }, class_name: "Location"
  has_one :dropoff_location, -> { where(location_type: "dropoff") }, class_name: "Location"

  before_create :set_status
  before_save :set_estimated_ride_price, if: :ride_id_changed?

  def set_estimated_ride_price
    Ride.where(id: self.ride_id).update_all(estimated_price: (Booking.where(ride_id: self.ride_id).pluck(:distance_km) + [ self.distance_km ]).sum * 2)
  end

  enum :status, { pending: "pending", accepted: "accepted", in_progress: "in_progress", rejected: "rejected", completed: "completed", cancelled: "cancelled" }, prefix: true

  accepts_nested_attributes_for :locations, allow_destroy: true

  scope :pending, -> { where(status: "pending") }
  scope :active, -> { where(status: [ "pending", "accepted", "in_progress" ]) }
  scope :pending, -> { where(status: :pending) }
  scope :active, -> { where(status: [ "accepted", "in_progress" ]) }
  scope :past, -> { where(status: [ "completed", "cancelled" ]) }

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
end
