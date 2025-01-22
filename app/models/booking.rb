class Booking < ApplicationRecord
  belongs_to :passenger, class_name: "PassengerProfile", foreign_key: :passenger_id
  belongs_to :ride, optional: true

  before_save :set_status

  enum :status, { pending: "pending", accepted: "accepted", rejected: "rejected" }

  def set_status
    self.status = "pending"
  end
end
