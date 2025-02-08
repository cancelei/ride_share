class Vehicle < ApplicationRecord
  include Discard::Model
  default_scope -> { kept }

  belongs_to :driver_profile, -> { with_discarded }
  has_many :rides, -> { with_discarded }, dependent: :destroy
end
