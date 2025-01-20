class PassengerProfile < ApplicationRecord
  belongs_to :user

  validate :only_one_active_passenger_profile_per_user

  def only_one_active_passenger_profile_per_user
    if PassengerProfile.where(user: user).count > 0
      errors.add(:base, "Only one active passenger profile per user is allowed")
    end
  end
end
