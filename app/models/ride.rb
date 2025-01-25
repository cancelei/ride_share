class Ride < ApplicationRecord
  belongs_to :driver, class_name: "DriverProfile", foreign_key: :driver_id
  has_many :bookings

  before_create :set_status
  after_save :update_booking, -> { booking_id.present? }

  attr_accessor :booking_id

  enum :status, { pending: "pending", accepted: "accepted", ongoing: "ongoing", completed: "completed" }

  scope :active, -> { where("start_time >= ?", Time.current) }
  scope :past, -> { where("start_time < ?", Time.current) }

  def set_status
    self.status = "pending"
  end

  def update_booking
    Booking.where(id: self.booking_id).update_all(status: "accepted", ride_id: self.id)

    self.booking_id = nil
  end

  def status_color
    case status
    when "scheduled" then "bg-green-100 text-green-800"
    when "in_progress" then "bg-blue-100 text-blue-800"
    when "completed" then "bg-gray-100 text-gray-800"
    when "cancelled" then "bg-red-100 text-red-800"
    end
  end

  def can_join?(user)
    return false unless user
    status == "scheduled" && !participants.include?(user)
  end
end
