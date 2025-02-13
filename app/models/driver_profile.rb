class DriverProfile < ApplicationRecord
  include Discard::Model
  default_scope -> { kept }

  belongs_to :user, -> { with_discarded }
  has_many :vehicles, -> { with_discarded }, dependent: :destroy
  has_many :rides, -> { with_discarded }, foreign_key: "driver_id", dependent: :destroy

  validates :license, :license_issuer, presence: true
  validate :at_least_one_payment_address
  validate :only_one_active_driver_profile_per_user, on: :create

  def only_one_active_driver_profile_per_user
    if DriverProfile.where(user: user).count > 0
      errors.add(:base, "Only one active driver profile per user is allowed")
    end
  end

  def at_least_one_payment_address
    unless bitcoin_address.present? || ethereum_address.present? || icc_address.present?
      errors.add(:base, "At least one payment address (Bitcoin, Ethereum, or ICC) must be provided.")
    end
  end

  belongs_to :selected_vehicle, class_name: "Vehicle", optional: true
end
