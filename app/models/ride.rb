class Ride < ApplicationRecord
  belongs_to :driver

  enum :status, { pending: "pending", accepted: "accepted", ongoing: "ongoing", completed: "completed", cancelled: "cancelled" }
  enum :ride_type, { shared_public: "shared_public", shared_private: "shared_private", solo_private: "solo_private" }
end
