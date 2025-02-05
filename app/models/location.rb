class Location < ApplicationRecord
  include Discard::Model
  default_scope -> { kept }

  belongs_to :booking, -> { with_discarded }, optional: true
end
