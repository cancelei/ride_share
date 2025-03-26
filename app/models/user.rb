class User < ApplicationRecord
  include DriverLocationBroadcaster
  include Discard::Model
  include EmailNotification
  default_scope -> { kept }
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one_attached :avatar

  validates :avatar,
  content_type: {
    in: %w[image/png image/jpeg],
    message: "must be a PNG, JPEG, or JPG"
  },
  size: {
    less_than: 5.megabytes,
    message: "must be less than 5MB"
  },
  allow_nil: true

  enum :role, { admin: 0, driver: 1, passenger: 2, company: 3 }, prefix: true

  has_one :driver_profile, -> { with_discarded }, dependent: :destroy
  has_one :passenger_profile, -> { with_discarded }, dependent: :destroy
  has_one :company_profile, -> { with_discarded }, dependent: :destroy

  before_discard :discard_profiles
  before_undiscard :undiscard_profiles

  # Configure email notifications
  notify_by_email after_create: true

  # Email notification methods
  def send_creation_email
    deliver_email(UserMailer, :welcome_email, self)
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def update_location(latitude, longitude)
    update(
      current_latitude: latitude,
      current_longitude: longitude,
      location_updated_at: Time.current
    )
  end

  def current_location
    return nil if current_latitude.blank? || current_longitude.blank?

    coordinates = { latitude: current_latitude, longitude: current_longitude }
    address = Geocoder.address([ current_latitude, current_longitude ])

    {
      coordinates: coordinates,
      address: address,
      updated_at: location_updated_at
    }
  end

  def initials
    full_name.split.map(&:first).join.upcase
  end

  private

  def discard_profiles
    driver_profile&.discard
    passenger_profile&.discard
    company_profile&.discard
  end

  def undiscard_profiles
    driver_profile&.undiscard
    passenger_profile&.undiscard
    company_profile&.undiscard
  end
end
