class Booking < ApplicationRecord
  belongs_to :passenger, class_name: "PassengerProfile", foreign_key: :passenger_id
  belongs_to :ride, optional: true
  has_many :locations, dependent: :destroy
  has_one :pickup_location, -> { where(location_type: "pickup") }, class_name: "Location"
  has_one :dropoff_location, -> { where(location_type: "dropoff") }, class_name: "Location"

  before_save :set_status

  enum :status, { pending: "pending", accepted: "accepted", in_progress: "in_progress", rejected: "rejected", completed: "completed", cancelled: "cancelled" }

  accepts_nested_attributes_for :locations, allow_destroy: true

  scope :active, -> { where(status: [ "pending", "accepted", "in_progress" ]) }
  scope :past, -> { where(status: [ "completed", "cancelled" ]) }

  def pickup
    pickup_location&.address
  end

  def dropoff
    dropoff_location&.address
  end

  def calculate_distance_to_driver
    return nil unless ride&.driver&.user&.current_latitude && ride&.driver&.user&.current_longitude

    pickup_coords = Geocoder.coordinates(pickup)
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
