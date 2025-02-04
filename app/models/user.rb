class User < ApplicationRecord
  include DriverLocationBroadcaster
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { admin: 0, driver: 1, passenger: 2 }, prefix: true

  has_one :driver_profile, dependent: :destroy
  has_one :passenger_profile, dependent: :destroy

  after_create :send_welcome_email

  def send_welcome_email
    if Rails.env.production?
      UserMailer.welcome_email(self).deliver_now
    else
      puts "Welcome email not sent in development environment"
    end
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
    broadcast_location(latitude, longitude) if driver_profile.present?
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
end
