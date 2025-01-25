class User < ApplicationRecord
  include DriverLocationBroadcaster
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { admin: 0, driver: 1, passenger: 2 }, prefix: true

  has_one :driver_profile, dependent: :destroy
  has_one :passenger_profile, dependent: :destroy
end
