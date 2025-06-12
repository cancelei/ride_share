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

  scope :active_rides, -> { includes(:ride_statuses).where(ride_statuses: { status: [ :accepted, :waiting_for_passenger_boarding, :in_progress, :rating_required ] }) }
  scope :passenger_active, ->(user_id) { includes(:ride_statuses).where(ride_statuses: { status: [ :pending, :accepted, :waiting_for_passenger_boarding, :in_progress, :rating_required, :waiting_for_passenger_boarding ] }).where.not(rides: { id: RideStatus.where(status: :cancelled, user_id: user_id).pluck(:ride_id) }) }
  scope :driver_pending, ->(user_id) { includes(:ride_statuses).where(ride_statuses: { status: [ :pending ] }).where.not(rides: { id: RideStatus.where(status: :cancelled, user_id: user_id).pluck(:ride_id) }) }
  scope :driver_active, ->(user_id) { includes(:ride_statuses).where(ride_statuses: { status: [ :accepted, :waiting_for_passenger_boarding, :in_progress, :rating_required ] }).where.not(rides: { id: RideStatus.where(status: :cancelled, user_id: user_id).pluck(:ride_id) }) }
  belongs_to :driver, class_name: "DriverProfile", optional: true
  belongs_to :passenger, class_name: "PassengerProfile", optional: true
  belongs_to :vehicle, optional: true
  belongs_to :company_profile, optional: true
  has_many :ratings, dependent: :destroy
  has_many :ride_statuses, dependent: :destroy

  before_create :generate_security_code, :calculate_distance_and_duration
  after_update :check_status, :broadcast_status_update
  after_create :set_status, :ensure_status_set, :notify_available_drivers, :send_creation_notification
  before_validation :set_coordinates_from_params
  before_save :sync_locations

  scope :historical_rides, ->(user_id) { includes(:ride_statuses).where(ride_statuses: { status: [ :completed, :cancelled ] }).where.not(rides: { id: RideStatus.where(user_id: user_id, status: :pending).pluck(:ride_id) }) }
  scope :last_thirty_days, -> { where("start_time > ?", 30.days.ago) }
  scope :past, -> { includes(:ride_statuses).where(ride_statuses: { status: [ :completed ] }).where.not(rides: { id: RideStatus.where(status: :pending).pluck(:ride_id) }) }
  scope :pending, -> { joins(:ride_statuses).where(ride_statuses: { status: [ :pending ] }) }
  scope :completed_rides, -> { includes(:ride_statuses).where(ride_statuses: { status: [ :completed ] }) }
  scope :completed, -> { includes(:ride_statuses).where(ride_statuses: { status: [ :completed ] }).where.not(rides: { id: RideStatus.where(status: :pending).pluck(:ride_id) }) }
  scope :cancelled_rides, -> { includes(:ride_statuses).where(ride_statuses: { status: [ :cancelled ] }) }
  scope :for_company, ->(company_id) { where(company_profile_id: company_id).includes(:driver, :passenger).order("rides.scheduled_time desc") }

  scope :total_estimated_price_for_24_hours, -> {
    where("created_at >= ? AND paid = true", 1.day.ago)
    .sum(:estimated_price)
  }

  scope :total_estimated_price_for_last_week, -> {
    where("rides.created_at >= ? AND paid = true", 1.week.ago)
    .sum(:estimated_price)
  }

  scope :total_estimated_price_for_last_thirty_days, -> {
    where("rides.created_at >= ? AND paid = true", 30.days.ago)
    .sum(:estimated_price)
  }

  validates :pickup_address, presence: true
  validates :dropoff_address, presence: true

  validates :driver, presence: true, if: -> { accepted? || in_progress? || completed? }
  validates :vehicle, presence: true, if: -> { accepted? || in_progress? || completed? }
  validates :scheduled_time, presence: true, if: -> { passenger.present? }
  validates :requested_seats, presence: true, numericality: { greater_than: 0 }, if: -> { passenger.present? }

  attribute :paid, :boolean, default: false

  def status
    ride_statuses&.order(:updated_at)&.last&.status
  end

  def accepted?
    ride_statuses.any?(&:accepted?)
  end

  def in_progress?
    ride_statuses.any?(&:in_progress?)
  end

  def completed?
    ride_statuses.any?(&:completed?)
  end

  def waiting_for_passenger_boarding?
    ride_statuses.any?(&:waiting_for_passenger_boarding?)
  end

  def self.active_driver_rides(driver_id)
    active_rides.where(driver_id: driver_id)
  end

  def titleize
    status.to_s.humanize
  end

  def can_start?
    accepted? && driver.present? && vehicle.present?
  end

  def can_complete?
    in_progress?
  end

  def can_be_cancelled_by_driver?
    waiting_for_passenger_boarding? || (accepted? && (scheduled_time - Time.now) / 1.hour > 4)
  end

  def finish!
    self.end_time = Time.current
    self.status = :completed

    save!
  end

  def accept!
    save!

    ride_statuses.where(user_id: [ passenger.user_id, driver.user_id ]).update_all(status: :accepted)
  end

  def driver_cancels
    ride_statuses.find_by(user_id: driver.user_id)&.update_column(:status, :cancelled) if driver.present?

    ride_statuses.find_by(user_id: passenger.user_id).update(status: :pending)

    update(driver_id: nil, vehicle_id: nil)
  end

  def waiting!
    update(arrived_time: Time.current)
    ride_statuses.where(user_id: [ passenger.user_id, driver.user_id ]).update_all(status: :waiting_for_passenger_boarding)
  end

  def in_progress!
    update(start_time: Time.current)
    ride_statuses.where(user_id: [ passenger.user_id, driver.user_id ]).update_all(status: :in_progress)
  end

  alias :start! :in_progress!

  def complete!
    update(end_time: Time.current)
    ride_statuses.where(user_id: [ passenger.user_id, driver.user_id ]).update_all(status: :completed)
  end

  alias :finish! :complete!

  def cancel!
    ride_statuses.where(user_id: [ passenger.user_id, driver&.user_id ]).update_all(status: :cancelled)
  end

  def set_status
    ride_statuses.find_or_create_by(user_id: passenger_id)
  end

  def check_status
    ride_statuses.find_or_create_by(user_id: passenger_id) if passenger_id
    ride_statuses.find_or_create_by(user_id: driver_id) if driver_id
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
    where("rides.created_at >= ?", 1.week.ago).sum(:estimated_price)
  end

  def calculate_price
    return unless distance_km.present?

    # Base fare
    base_fare = 5.0

    # Price per kilometer
    price_per_km = 1.5

    # Calculate price based on distance
    calculated_price = base_fare + (distance_km.to_f * price_per_km)

    # Round to 2 decimal places and store
    self.estimated_price = calculated_price.round(2)
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

  # Send notification when ride is first created
  def send_creation_notification
    deliver_email(UserMailer, :ride_confirmation, self)
  end

  private

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
    # Only set location from address if location is blank and we have an address
    if pickup_location.blank? && pickup_address.present?
      self.pickup_location = pickup_address
    end

    if dropoff_location.blank? && dropoff_address.present?
      self.dropoff_location = dropoff_address
    end

    # Only set address from location if address is blank and we have a location
    if pickup_address.blank? && pickup_location.present?
      self.pickup_address = pickup_location
    end

    if dropoff_address.blank? && dropoff_location.present?
      self.dropoff_address = dropoff_location
    end

    # Calculate distance and price if we have coordinates
    if pickup_lat.present? && pickup_lng.present? &&
       dropoff_lat.present? && dropoff_lng.present?
      calculate_distance_and_duration
    end
  end

  def should_calculate_price?
    pickup_lat.present? && pickup_lng.present? &&
    dropoff_lat.present? && dropoff_lng.present? &&
    estimated_price.nil?
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
