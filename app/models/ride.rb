class Ride < ApplicationRecord
  belongs_to :driver, class_name: "DriverProfile", foreign_key: :driver_id
  has_many :bookings

  before_create :set_status
  after_save :update_booking, -> { booking_id.present? }

  attr_accessor :booking_id

  enum :status, { pending: "pending", accepted: "accepted", ongoing: "ongoing", completed: "completed" }

  def set_status
    self.status = "pending"
  end

  def update_booking
    Booking.where(id: self.booking_id).update_all(status: "accepted", ride_id: self.id)

    self.booking_id = nil
  end
end
