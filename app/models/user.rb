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
  end

  def current_location
    return nil unless location_coordinates.present?

    {
      coordinates: location_coordinates,
      updated_at: location_updated_at,
      address: location_address
    }
  end

  def location_coordinates
    { latitude: current_latitude, longitude: current_longitude }
  end

  def location_address
    Geocoder.address(location_coordinates)
  end
end
