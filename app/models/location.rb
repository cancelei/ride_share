class Location < ApplicationRecord
  include Discard::Model
  include AddressFormatter
  default_scope -> { kept }

  belongs_to :booking, -> { with_discarded }, optional: true

  before_save :format_address_before_save

  private

  def format_address_before_save
    self.address = format_address(address) if address_changed?
  end
end
