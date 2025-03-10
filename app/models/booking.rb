class Booking < ApplicationRecord
  include Discard::Model
  include RideStatusBroadcaster
  include PriceCalculator
  default_scope -> { kept }

  belongs_to :passenger, -> { with_discarded }, class_name: "PassengerProfile", foreign_key: :passenger_id
  belongs_to :ride, -> { with_discarded }, optional: true
  has_many :locations, -> { with_discarded }, dependent: :destroy
  has_one :pickup_location, -> { where(location_type: "pickup") }, class_name: "Location", dependent: :destroy
  has_one :dropoff_location, -> { where(location_type: "dropoff") }, class_name: "Location", dependent: :destroy

  before_create :set_status
  before_save :set_estimated_ride_price, if: :ride_id_changed?

  after_update :broadcast_status_update
  after_create :broadcast_status_update
  after_commit :broadcast_update
  after_commit :broadcast_to_drivers, on: :create
  after_commit :broadcast_cancellation, if: -> { saved_change_to_status? && status == "cancelled" }
  after_create :send_booking_confirmation
  after_update :send_status_update_emails

  validates :scheduled_time, presence: true
  validate :has_valid_locations

  enum :status, { pending: "pending", accepted: "accepted", in_progress: "in_progress", rejected: "rejected", completed: "completed", cancelled: "cancelled" }, prefix: true

  accepts_nested_attributes_for :locations

  scope :active, -> { where(status: [ "pending", "accepted", "in_progress" ]) }
  scope :pending, -> { where(status: "pending") }
  scope :past, -> { where(status: [ "completed" ]) }
  scope :cancelled, -> { where(status: "cancelled") }

  def status_pending?
    status == "pending"
  end

  def status_accepted?
    status == "accepted"
  end

  def status_in_progress?
    status == "in_progress"
  end

  def status_completed?
    status == "completed"
  end

  def status_cancelled?
    status == "cancelled"
  end

  def has_valid_locations
    pickup = locations.find { |l| l.location_type == "pickup" }
    dropoff = locations.find { |l| l.location_type == "dropoff" }

    if pickup.nil? || pickup.address.blank?
      errors.add(:base, "Pickup location is required")
    end

    if dropoff.nil? || dropoff.address.blank?
      errors.add(:base, "Dropoff location is required")
    end
  end

  def pickup
    pickup_location&.address
  end

  def dropoff
    dropoff_location&.address
  end

  def calculate_distance_to_driver
    return nil unless ride&.driver&.user&.current_latitude && ride&.driver&.user&.current_longitude

    pickup_coords = Geocoder.coordinates(status_accepted? ? pickup : dropoff)
    return nil unless pickup_coords

    driver_coords = [ ride.driver.user.current_latitude, ride.driver.user.current_longitude ]

    distance = Geocoder::Calculations.distance_between(pickup_coords, driver_coords, units: :km)
    distance.round(1)
  end

  def calculate_eta_minutes
    return nil unless distance_to_pickup = calculate_distance_to_driver

    # Assuming average speed of 40 km/h in city traffic
    (distance_to_pickup * 1.5).round
  end

  private

  def set_status
    self.status = "pending"
  end

  def broadcast_update
    broadcast_to_passenger
    broadcast_to_driver if ride&.driver
  end

  def broadcast_to_passenger
    Turbo::StreamsChannel.broadcast_update_to(
      "user_#{passenger.user_id}_dashboard",
      target: "rides_content",
      partial: "dashboard/rides_content",
      locals: {
        my_bookings: passenger.bookings,
        user: passenger.user
      }
    )
  end

  def broadcast_to_driver
    return unless ride&.driver&.user_id

    Turbo::StreamsChannel.broadcast_update_to(
      "user_#{ride.driver.user_id}_dashboard",
      target: "rides_content",
      partial: "dashboard/rides_content",
      locals: {
        my_bookings: ride.bookings,
        user: ride.driver.user
      }
    )
  end

  def broadcast_to_drivers
    return unless status == "pending"

    pending_bookings = Booking.pending.includes(:passenger, :ride)

    User.role_driver.find_each do |driver|
      Turbo::StreamsChannel.broadcast_replace_to(
        "user_#{driver.id}_dashboard",
        target: "pending_bookings",
        partial: "dashboard/pending_bookings",
        locals: {
          pending_bookings: pending_bookings,
          current_user: driver
        }
      )
    end
  end

  def broadcast_cancellation
    broadcast_to_all_drivers
    broadcast_to_assigned_driver if ride&.driver
  end

  def broadcast_to_all_drivers
    pending_bookings = Booking.pending.includes(:passenger, :ride)

    User.role_driver.find_each do |driver|
      Turbo::StreamsChannel.broadcast_replace_to(
        "user_#{driver.id}_dashboard",
        target: "pending_bookings",
        partial: "dashboard/pending_bookings",
        locals: {
          pending_bookings: pending_bookings,
          current_user: driver
        }
      )
    end
  end

  def broadcast_to_assigned_driver
    Turbo::StreamsChannel.broadcast_replace_to(
      "user_#{ride.driver.user_id}_dashboard",
      target: "rides_content",
      partial: "dashboard/rides_content",
      locals: {
        my_bookings: ride.bookings,
        active_rides: ride.driver.rides.active,
        pending_bookings: Booking.pending,
        past_rides: ride.driver.rides.past
      }
    )
  end

  def send_booking_confirmation
    UserMailer.booking_confirmation(self).deliver_later
    Rails.logger.info "Booking confirmation email queued for delivery to #{passenger.user.email}"
  end

  def send_status_update_emails
    Rails.logger.info "Processing status update emails for booking #{id}, status: #{status}"

    # Only send emails if the status has actually changed
    return unless saved_change_to_status?

    case status
    when "accepted"
      UserMailer.ride_accepted(self).deliver_later
      Rails.logger.info "Ride accepted email queued for delivery to #{passenger.user.email}"
    when "in_progress"
      UserMailer.driver_arrived(self).deliver_later
      Rails.logger.info "Driver arrived email queued for delivery to #{passenger.user.email}"
    when "completed"
      # Send passenger email first
      begin
        UserMailer.ride_completion_passenger(self).deliver_later
        Rails.logger.info "Ride completion email queued for delivery to #{passenger.user.email}"
      rescue => e
        Rails.logger.error "Failed to send passenger completion email: #{e.message}"
      end

      # Send driver email with error handling
      begin
        if ride&.driver&.user&.email.present?
          UserMailer.ride_completion_driver(self).deliver_later
          Rails.logger.info "Ride completion email queued for delivery to driver: #{ride.driver.user.email}"
        else
          Rails.logger.error "Cannot send driver completion email - missing driver email"
        end
      rescue => e
        Rails.logger.error "Failed to send driver completion email: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end
  end

  def set_estimated_ride_price
    return unless ride_id.present?

    # Calculate total distance for all bookings in this ride
    total_distance = Booking.where(ride_id: ride_id)
                           .pluck(:distance_km)
                           .sum + (distance_km || 0)

    # Temporarily set the ride's distance_km for calculation
    original_distance = ride.distance_km
    ride.distance_km = total_distance

    # Use the PriceCalculator module to calculate the price
    total_price = ride.calculate_estimated_price

    # Ensure minimum price requirement is met
    total_price = [ total_price, 5.01 ].max

    # Restore original distance and update the price
    ride.distance_km = original_distance
    ride.update_column(:estimated_price, total_price)
  end
end
