class Ride < ApplicationRecord
  belongs_to :driver, class_name: "DriverProfile", foreign_key: "driver_id", optional: true

  enum :status, { pending: "pending", accepted: "accepted", ongoing: "ongoing", completed: "completed", cancelled: "cancelled" }
  enum :ride_type, { shared_public: "shared_public", shared_private: "shared_private", solo_private: "solo_private" }

  before_save :set_default_values

  def set_default_values
    self.status ||= "pending"
  end
end
