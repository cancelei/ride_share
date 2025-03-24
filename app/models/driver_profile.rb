class DriverProfile < ApplicationRecord
  include Discard::Model
  default_scope -> { kept }

  belongs_to :user, -> { with_discarded }
  belongs_to :company_profile, -> { with_discarded }, optional: true
  has_many :vehicles, -> { with_discarded }, dependent: :destroy
  has_many :rides, -> { with_discarded }, foreign_key: "driver_id", dependent: :destroy
  has_many :company_drivers, dependent: :destroy
  belongs_to :selected_vehicle, class_name: "Vehicle", foreign_key: "selected_vehicle_id"

  validates :license, :license_issuer, presence: true
  validate :at_least_one_payment_address
  validate :only_one_active_driver_profile_per_user, on: :create
  after_save :check_company_driver

  def check_company_driver
    return unless saved_change_to_company_profile_id?

    if company_profile.present?
      CompanyDriver.create(company_profile_id: company_profile_id, driver_profile_id: self.id)
    else
      CompanyDriver.where(driver_profile_id: self.id).destroy_all
    end
  end

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
end
