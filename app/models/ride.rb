require "net/http"
require "uri"
require "json"

class Ride < ApplicationRecord
  include Discard::Model
  include RideStatusBroadcaster
  include ActionView::RecordIdentifier
  include PriceCalculator
  include EmailNotification
  default_scope -> { kept }

  belongs_to :driver, class_name: "DriverProfile", optional: true
  belongs_to :passenger, class_name: "PassengerProfile", optional: true
  belongs_to :vehicle, optional: true

  before_create :set_status, :generate_security_code, :calculate_distance_and_duration
  after_update :broadcast_status_update
  after_commit :broadcast_ride_status, if: :saved_change_to_status?
  after_create :ensure_status_set, :notify_available_drivers
  before_validation :set_coordinates_from_params
  before_save :sync_locations

  enum :status, {
    pending: "pending",
    accepted: "accepted",
    waiting_for_passenger_boarding: "waiting_for_passenger_boarding",
    in_progress: "in_progress",
    completed: "completed",
    cancelled: "cancelled"
  }

  scope :active_rides, -> { where(status: [ :pending, :accepted, :waiting_for_passenger_boarding, :in_progress ]) }
  scope :historical_rides, -> { where(status: [ :completed, :cancelled ]) }
  scope :last_thirty_days, -> { where("start_time > ?", 30.days.ago) }
  scope :past, -> { where(status: [ :completed ]) }
  scope :completed_rides, -> { where(status: :completed) }
  scope :cancelled_rides, -> { where(status: :cancelled) }

  scope :total_estimated_price_for_24_hours, -> {
    where("created_at >= ? AND paid = true", 1.day.ago)
    .sum(:estimated_price)
  }

  scope :total_estimated_price_for_last_week, -> {
    where("created_at >= ? AND paid = true", 1.week.ago)
    .sum(:estimated_price)
  }

  scope :total_estimated_price_for_last_thirty_days, -> {
    where("created_at >= ? AND paid = true", 30.days.ago)
    .sum(:estimated_price)
  }

  validates :pickup_location, :dropoff_location, presence: true, if: -> {
    (accepted? || in_progress? || completed?) &&
    pickup_address.blank? && dropoff_address.blank?
  }

  validates :pickup_address, :dropoff_address, presence: true, if: -> {
    (accepted? || in_progress? || completed?) &&
    pickup_location.blank? && dropoff_location.blank?
  }

  validates :driver, presence: true, if: -> { accepted? || in_progress? || completed? }
  validates :vehicle, presence: true, if: -> { accepted? || in_progress? || completed? }
  validates :scheduled_time, presence: true, if: -> { passenger.present? }
  validates :requested_seats, presence: true, numericality: { greater_than: 0 }, if: -> { passenger.present? }

  attribute :participants_count, :integer, default: 0
  attribute :paid, :boolean, default: false

  # Configure email notifications for different ride statuses
  notify_by_email after_update: true, on: :handle_status_change_notifications
  notify_by_email after_create: true, on: :send_creation_notification

  def titleize
    status.to_s.humanize
  end

  def assign_driver(driver, vehicle)
    update(driver: driver, vehicle: vehicle)
  end

  def can_start?
    accepted? && driver.present? && vehicle.present?
  end

  def can_complete?
    in_progress?
  end

  def can_be_cancelled_by_driver?
    waiting_for_passenger_boarding?
  end

  def start!
    self.start_time = Time.current
    self.status = :in_progress

    save!
  end

  def finish!
    self.end_time = Time.current
    self.status = :completed

    save!
  end

  def set_status
    Rails.logger.debug "RIDE DEBUG: Inside set_status, current status: #{status.inspect}"
    self.status ||= "pending"
    Rails.logger.debug "RIDE DEBUG: After set_status, status: #{status.inspect}"
  end

  def status_color
    case status
    when "pending" then "bg-yellow-100 text-yellow-800"
    when "accepted" then "bg-blue-100 text-blue-800"
    when "waiting_for_passenger_boarding" then "bg-purple-100 text-purple-800"
    when "in_progress" then "bg-indigo-100 text-indigo-800"
    when "completed" then "bg-green-100 text-green-800"
    when "cancelled" then "bg-red-100 text-red-800"
    else "bg-gray-100 text-gray-800"
    end
  end

  def can_join?(user)
    return false unless user
    status == "scheduled" && !participants.include?(user)
  end

  def google_maps_url
    return unless pickup_location.present? && dropoff_location.present?

    origin = CGI.escape(pickup_location.to_s)
    destination = CGI.escape(dropoff_location.to_s)

    url = "https://www.google.com/maps/dir/?api=1&origin=#{origin}&destination=#{destination}"
    url += "&travelmode=driving"

    url
  end

  def participants_count
    requested_seats || 0
  end

  def verify_security_code(code)
    security_code == code
  end

  def mark_paid!
    update(paid: !paid, paid_at: paid? ? nil : Time.current).tap do |success|
      broadcast_payment_update if success
    end
  end

  def self.total_estimated_price_for_24_hours
    where("created_at >= ?", 1.day.ago).sum(:estimated_price)
  end

  def self.total_estimated_price_for_last_week
    where("created_at >= ?", 1.week.ago).sum(:estimated_price)
  end

  def calculate_price
    return unless distance_km.present?

    # Base fare
    base_fare = 5.0

    # Price per kilometer
    price_per_km = 1.5

    # Calculate price based on distance
    self.estimated_price = base_fare + (distance_km.to_f * price_per_km)
  end

  def calculate_distance_and_duration
    return if pickup_lat.blank? || pickup_lng.blank? || dropoff_lat.blank? || dropoff_lng.blank?

    response = GooglePlacesService.new.fetch_distance_matrix(pickup_lat, pickup_lng, dropoff_lat, dropoff_lng)

    return if response.blank? || response.dig("rows", 0, "elements", 0, "status") != "OK"

    distance_meters = response.dig("rows", 0, "elements", 0, "distance", "value")
    duration_seconds = response.dig("rows", 0, "elements", 0, "duration", "value")

    self.distance_km = (distance_meters / 1000.0).round(2)
    self.estimated_duration_minutes = (duration_seconds / 60.0).round

    calculate_price
  end

  # Handle notifications based on status changes
  def handle_status_change_notifications
    if saved_change_to_status?
      case status
      when "accepted"
        deliver_email(UserMailer, :ride_accepted, self)
      when "waiting_for_passenger_boarding"
        deliver_email(UserMailer, :driver_arrived, self)
      when "in_progress"
        deliver_email(UserMailer, :ride_in_progress, self)
      when "completed"
        deliver_email(UserMailer, :ride_completion_passenger, self)
        deliver_email(UserMailer, :ride_completion_driver, self)
      end
    end
  end

  # Send notification when ride is first created
  def send_creation_notification
    deliver_email(UserMailer, :ride_confirmation, self)
  end

  private

  def broadcast_ride_status
    Rails.logger.debug "DEBUG: Ride#broadcast_ride_status called for ride #{id}"
    Rails.logger.debug "DEBUG: Ride status: #{status}"
    Rails.logger.debug "DEBUG: Status changed from #{status_before_last_save} to #{status}"

    # Broadcast to the passenger
    if passenger.present?
      Rails.logger.debug "DEBUG: Broadcasting to passenger: #{passenger.user_id}"
      passenger_user = passenger.user

      Turbo::StreamsChannel.broadcast_replace_to(
        "user_#{passenger.user_id}_dashboard",
        target: "rides_content",
        partial: "dashboard/rides_content",
        locals: {
          my_rides: Ride.where(passenger_id: passenger.id),
          params: { type: determine_tab_type },
          user: passenger_user
        }
      )

      # Direct broadcast to the specific ride card when status changes to accepted or waiting_for_passenger_boarding
      if status == "accepted" || status == "waiting_for_passenger_boarding" || status == "in_progress"
        Rails.logger.debug "DEBUG: Broadcasting status #{status} to passenger's ride card"

        Turbo::StreamsChannel.broadcast_replace_to(
          "user_#{passenger.user_id}_rides",
          target: "ride_#{id}",
          partial: "rides/ride_card",
          locals: {
            ride: self,
            current_user: passenger_user
          }
        )
      end
    end

    # Broadcast to the driver
    if driver.present?
      Rails.logger.debug "DEBUG: Broadcasting to driver: #{driver.user_id}"
      driver_user = driver.user

      # Get the driver's rides
      driver_rides = Ride.where(driver_id: driver.id)

      Turbo::StreamsChannel.broadcast_replace_to(
        "user_#{driver.user_id}_dashboard",
        target: "rides_content",
        partial: "dashboard/rides_content",
        locals: {
          my_rides: driver_rides,
          params: { type: determine_tab_type },
          user: driver_user
        }
      )

      # Direct broadcast to the specific ride card when status changes to accepted or other states
      if status == "accepted" || status == "waiting_for_passenger_boarding" || status == "in_progress"
        Rails.logger.debug "DEBUG: Broadcasting status #{status} to driver's ride card"

        Turbo::StreamsChannel.broadcast_replace_to(
          "user_#{driver.user_id}_rides",
          target: "ride_#{id}",
          partial: "rides/ride_card",
          locals: {
            ride: self,
            current_user: driver_user
          }
        )
      end
    end
  end

  def generate_security_code
    self.security_code = sprintf("%04d", rand(10000))
  end

  def broadcast_payment_update
    # Get fresh calculations after the update
    fresh_past_rides = driver.rides.past.order(created_at: :desc).limit(5)
    weekly_total = driver.rides.past.total_estimated_price_for_last_week
    monthly_total = driver.rides.past.total_estimated_price_for_last_thirty_days

    Turbo::StreamsChannel.broadcast_replace_to(
      [ driver.user, "dashboard" ],
      target: "past_rides",
      partial: "dashboard/past_rides",
      locals: {
        past_rides: fresh_past_rides,
        last_week_rides_total: weekly_total,
        monthly_rides_total: monthly_total
      }
    )
  end

  def validate_minimum_price
    if estimated_price.nil? || estimated_price <= 5
      errors.add(:estimated_price, "must be greater than $5.00")
    end
  end

  def determine_tab_type
    case status
    when "pending", "accepted", "waiting_for_passenger_boarding", "in_progress"
      "active"
    when "completed", "cancelled"
      "past"
    else
      "all"
    end
  end

  def ensure_status_set
    Rails.logger.debug "RIDE DEBUG: Inside ensure_status_set, current status: #{status.inspect}"
    # Only update if status is nil
    if status.nil?
      Rails.logger.debug "RIDE DEBUG: Status is nil, updating to pending"
      update_column(:status, "pending")
      Rails.logger.debug "RIDE DEBUG: After update_column, status: #{reload.status.inspect}"
    end
  end

  def set_coordinates_from_params
    # Make sure we have latitude and longitude values
    # This is needed because the form might submit with different field names
    if pickup_lat.blank? && attributes["pickup_latitude"].present?
      self.pickup_lat = attributes["pickup_latitude"]
    end

    if pickup_lng.blank? && attributes["pickup_longitude"].present?
      self.pickup_lng = attributes["pickup_longitude"]
    end

    if dropoff_lat.blank? && attributes["dropoff_latitude"].present?
      self.dropoff_lat = attributes["dropoff_latitude"]
    end

    if dropoff_lng.blank? && attributes["dropoff_longitude"].present?
      self.dropoff_lng = attributes["dropoff_longitude"]
    end
  end

  def sync_locations
    # Synchronize pickup_location and pickup_address
    if pickup_address.present? && (pickup_location.blank? || pickup_location != pickup_address)
      self.pickup_location = pickup_address
    elsif pickup_location.present? && (pickup_address.blank? || pickup_address != pickup_location)
      self.pickup_address = pickup_location
    end

    # Synchronize dropoff_location and dropoff_address
    if dropoff_address.present? && (dropoff_location.blank? || dropoff_location != dropoff_address)
      self.dropoff_location = dropoff_address
    elsif dropoff_location.present? && (dropoff_address.blank? || dropoff_address != dropoff_location)
      self.dropoff_address = dropoff_location
    end
  end

  def notify_available_drivers
    Rails.logger.info "Checking if drivers should be notified for ride #{id}"

    # Only notify drivers if no specific driver is assigned yet and we have a passenger
    if driver_id.nil? && passenger.present?
      Rails.logger.info "Notifying drivers about new ride #{id} from #{pickup_address} to #{dropoff_address}"
      RideNotificationService.notify_drivers(self)
    else
      Rails.logger.info "Skipping driver notification for ride #{id}: " +
        "#{driver_id.present? ? 'driver already assigned' : 'no passenger present'}"
    end
  rescue => e
    Rails.logger.error "Error in notify_available_drivers for ride #{id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    # Don't raise the error to prevent ride creation from failing
  end
end
