class Rating < ApplicationRecord
  belongs_to :rateable, polymorphic: true
  belongs_to :rater, polymorphic: true

  validates :score, presence: true, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  # Allow a rater to rate multiple entities, but only rate the same entity once
  validates :rateable_id, uniqueness: { scope: [ :rateable_type, :rater_id, :rater_type ] }

  after_create :update_ride_status, if: -> { rateable_type == "Ride" }

  private

  def update_ride_status
    ride = rateable

    # Only complete the ride if it's in rating_required status
    if ride.rating_required?
      # Check if both driver and passenger have rated each other
      driver_rated = Rating.exists?(rater_type: "DriverProfile", rater_id: ride.driver.id, rateable: ride.passenger)
      passenger_rated = Rating.exists?(rater_type: "PassengerProfile", rater_id: ride.passenger.id, rateable: ride.driver)

      # Change status to completed only when both have rated
      ride.update(status: :completed) if driver_rated && passenger_rated
    end
  end
end
