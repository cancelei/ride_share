class DriverProfile < ApplicationRecord
  belongs_to :user

  validates :license, :license_issuer, presence: true

  validate :only_one_active_driver_profile_per_user

  def only_one_active_driver_profile_per_user
    if DriverProfile.where(user: user).count > 0
      errors.add(:base, "Only one active driver profile per user is allowed")
    end
  end

  has_many :vehicles, dependent: :destroy
  belongs_to :selected_vehicle, class_name: "Vehicle", optional: true
end
