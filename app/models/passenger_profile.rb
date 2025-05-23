class PassengerProfile < ApplicationRecord
  include Discard::Model
  default_scope -> { kept }

  belongs_to :user, -> { with_discarded }
  has_many :rides, -> { with_discarded }, foreign_key: "passenger_id", dependent: :destroy
  has_many :ratings, as: :rateable, dependent: :destroy
  has_many :given_ratings, as: :rater, class_name: "Rating", dependent: :destroy

  validate :only_one_active_passenger_profile_per_user, on: :create

  validates :whatsapp_number, phone: true

  def only_one_active_passenger_profile_per_user
    if PassengerProfile.where(user: user).count > 0
      errors.add(:base, "Only one active passenger profile per user is allowed")
    end
  end
end
