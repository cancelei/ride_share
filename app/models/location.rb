class Location < ApplicationRecord
  include Discard::Model
  include AddressFormatter
  default_scope -> { kept }

  belongs_to :booking, -> { with_discarded }, optional: true

  before_save :format_address_before_save

  validates :address, presence: true, unless: -> { latitude.present? && longitude.present? }
  validates :latitude, :longitude, numericality: true, allow_nil: true
  validates :location_type, inclusion: { in: %w[pickup dropoff] }
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

  scope :recent, -> { order(created_at: :desc) }
  scope :last_24_hours, -> { where("created_at >= ?", 24.hours.ago) }

  geocoded_by :address
  reverse_geocoded_by :latitude, :longitude

  after_validation :geocode, if: ->(obj) { obj.address.present? && (obj.latitude.blank? || obj.longitude.blank?) }
  after_validation :reverse_geocode, if: ->(obj) { obj.latitude.present? && obj.longitude.present? && obj.address.blank? }

  enum :location_type, { pickup: 0, dropoff: 1 }

  def to_s
    address.presence || "#{latitude}, #{longitude}"
  end

  def coordinates
    [ latitude, longitude ] if latitude.present? && longitude.present?
  end

  def formatted_address
    if address.present?
      # Remove any unnecessary details to keep the address clean
      address.split(",").first(2).join(", ")
    else
      "Location not available"
    end
  end

  def distance_to(other_location, units: :km)
    return nil unless coordinates && other_location.coordinates

    Geocoder::Calculations.distance_between(
      coordinates,
      other_location.coordinates,
      units: units
    ).round(1)
  end

  def eta_to(other_location, avg_speed_kmh: 40)
    distance = distance_to(other_location)
    return nil unless distance

    # Convert distance to time in minutes
    (distance / avg_speed_kmh * 60).round
  end

  private

  def format_address_before_save
    self.address = format_address(address) if address_changed?
  end
end
