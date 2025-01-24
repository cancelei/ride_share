class Booking < ApplicationRecord
  belongs_to :passenger, class_name: "PassengerProfile", foreign_key: :passenger_id
  belongs_to :ride, optional: true
  has_many :locations, dependent: :destroy
  has_one :pickup_location, -> { where(location_type: "pickup") }, class_name: "Location"
  has_one :dropoff_location, -> { where(location_type: "dropoff") }, class_name: "Location"

  before_save :set_status

  enum :status, { pending: "pending", accepted: "accepted", rejected: "rejected" }

  accepts_nested_attributes_for :locations

  def set_status
    self.status = "pending"
  end
end
