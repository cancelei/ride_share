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
  validates :phone_number, phone: true

  has_one :driver_profile, -> { with_discarded }, dependent: :destroy
  has_one :passenger_profile, -> { with_discarded }, dependent: :destroy
  has_one :company_profile, -> { with_discarded }, dependent: :destroy

  before_discard :discard_profiles
  before_undiscard :undiscard_profiles

  # Configure email notifications
  after_create :send_creation_email

  # For phone number formating
  before_save :normalize_phone_number

  # Returns the average rating across both driver and passenger profiles (if present)
  def average_rating
    ratings = []
    ratings += driver_profile.ratings.pluck(:score) if driver_profile&.persisted?
    ratings += passenger_profile.ratings.pluck(:score) if passenger_profile&.persisted?
    return nil if ratings.empty?
    (ratings.sum.to_f / ratings.size).round(2)
  end

  # Returns the average rating as a driver
  def average_driver_rating
    return nil unless driver_profile&.persisted?
    scores = driver_profile.ratings.pluck(:score)
    return nil if scores.empty?
    (scores.sum.to_f / scores.size).round(2)
  end

  # Returns the average rating as a passenger
  def average_passenger_rating
    return nil unless passenger_profile&.persisted?
    scores = passenger_profile.ratings.pluck(:score)
    return nil if scores.empty?
    (scores.sum.to_f / scores.size).round(2)
  end

  # Returns the average rating as a company
  def average_company_rating
    return nil unless company_profile&.persisted?
    scores = company_profile.company_drivers.joins(driver_profile: :ratings).pluck(:score)
    return nil if scores.empty?
    (scores.sum.to_f / scores.size).round(2)
  end

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


  def formatted_phone_number
    parsed = Phonelib.parse(phone_number)
    parsed.valid? ? parsed.international : phone_number
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

  def normalize_phone_number
    parsed = Phonelib.parse(phone_number)
    self.phone_number = parsed.e164 if parsed.valid?
  end
end
