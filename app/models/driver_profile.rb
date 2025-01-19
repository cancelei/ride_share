class DriverProfile < ApplicationRecord
  belongs_to :user

  validates :license, :license_issuer, presence: true

  has_many :vehicles, dependent: :destroy
  belongs_to :selected_vehicle, class_name: "Vehicle", optional: true
end
