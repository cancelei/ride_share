class PassengerProfile < ApplicationRecord
  belongs_to :user
  has_many :bookings, foreign_key: :passenger_id

  validate :only_one_active_passenger_profile_per_user, on: :create

  def only_one_active_passenger_profile_per_user
    if PassengerProfile.where(user: user).count > 0
      errors.add(:base, "Only one active passenger profile per user is allowed")
    end
  end
end
