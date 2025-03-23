class CompanyProfile < ApplicationRecord
  include Discard::Model
  default_scope -> { kept }

  belongs_to :user, -> { with_discarded }
  has_many :company_drivers, -> { with_discarded }, dependent: :destroy
  has_many :driver_profiles, through: :company_drivers

  validates :name, presence: true
end
