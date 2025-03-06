require "net/http"
require "uri"
require "json"

class Ride < ApplicationRecord
  include Discard::Model
  include RideStatusBroadcaster
  include ActionView::RecordIdentifier
  default_scope -> { kept }

  belongs_to :driver, -> { with_discarded }, class_name: "DriverProfile", foreign_key: :driver_id, optional: true
  has_many :bookings, -> { with_discarded }, dependent: :destroy
  has_many :passengers, through: :bookings
  belongs_to :vehicle, -> { with_discarded }, optional: true

  has_one :booking, dependent: :nullify
  belongs_to :passenger, class_name: "PassengerProfile", optional: true

  before_create :set_status, :generate_security_code
  before_save :save_participants
  after_save :update_booking, -> { booking_id.present? }
  after_update :broadcast_status_update
  after_commit :broadcast_ride_status, if: :saved_change_to_status?

  attr_accessor :booking_id

  enum :status, { pending: "pending", accepted: "accepted", ongoing: "ongoing", completed: "completed", cancelled: "cancelled" }

  scope :active, -> { where(status: [ "pending", "accepted", "in_progress" ]) }
  scope :past, -> { where("start_time < ?", Time.current) }
  scope :last_thirty_days, -> { where("start_time > ?", 30.days.ago) }
  scope :completed, -> { where(status: "completed") }
  scope :cancelled, -> { where(status: "cancelled") }

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

  validate :driver_has_vehicle

  broadcasts_to ->(ride) { [ ride.driver.user, "dashboard" ] }

  attribute :participants_count, :integer, default: 0
  attribute :paid, :boolean, default: false

  def can_start?(user)
    user.driver_profile == self.driver && self.status == "accepted"
  end

  def can_finish?(user)
    user.driver_profile == self.driver && self.status == "ongoing"
  end

  def start!
    self.start_time = Time.current
    self.status = "ongoing"

    # Update each booking individually to trigger callbacks
    self.bookings.each do |booking|
      booking.update(status: "in_progress")
    end

    save!
  end

  def finish!
    self.end_time = Time.current
    self.status = "completed"

    # Update each booking individually to trigger callbacks
    self.bookings.each do |booking|
      booking.update(status: "completed")
    end

    save!
  end

  def set_status
    self.status = "accepted"
  end

  def update_booking
    Booking.find_by(id: self.booking_id)&.update(status: "accepted", ride_id: self.id)

    self.booking_id = nil
  end

  def status_color
    case status
    when "scheduled" then "bg-green-100 text-green-800"
    when "in_progress" then "bg-blue-100 text-blue-800"
    when "completed" then "bg-gray-100 text-gray-800"
    when "cancelled" then "bg-red-100 text-red-800"
    end
  end

  def can_join?(user)
    return false unless user
    status == "scheduled" && !participants.include?(user)
  end

  def google_maps_url
    origin = CGI.escape(bookings.first.pickup.to_s)
    destination = CGI.escape(bookings.first.dropoff.to_s)

    # If there are multiple bookings, add them as waypoints
    waypoints = if bookings.count > 1
      bookings[1..-1].map do |booking|
        "via:#{CGI.escape(booking.pickup.to_s)}|via:#{CGI.escape(booking.dropoff.to_s)}"
      end.join("|")
    end

    url = "https://www.google.com/maps/dir/?api=1&origin=#{origin}&destination=#{destination}"
    url += "&waypoints=via:#{CGI.escape(bookings.first.pickup.to_s)}|#{waypoints}" if waypoints.present?
    url += "&travelmode=driving"

    url
  end

  def participants_count
    bookings.sum(:requested_seats)
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

  private

  def save_participants
    # Get the driver's vehicle capacity
    vehicle_capacity = driver.selected_vehicle&.seating_capacity ||
                      driver.vehicles.first&.seating_capacity || 0

    # Set initial available seats to vehicle capacity if not set
    self.available_seats ||= vehicle_capacity

    # Calculate total requested seats from all accepted bookings
    total_requested_seats = bookings.sum(:requested_seats)

    # If this is a new booking being added
    if booking_id.present?
      new_booking = Booking.find_by(id: booking_id)
      total_requested_seats += new_booking.requested_seats if new_booking
    end

    # Update available seats
    self.available_seats = [ vehicle_capacity - total_requested_seats, 0 ].max
  end

  def driver_has_vehicle
    unless driver&.vehicles&.any?
      errors.add(:base, "Driver must have at least one vehicle")
    end
  end

  def broadcast_ride_status
    # Broadcast to all passengers in this ride's bookings
    bookings.each do |booking|
      Turbo::StreamsChannel.broadcast_replace_to(
        "user_#{booking.passenger.user_id}_dashboard",
        target: "rides_content",
        partial: "dashboard/rides_content",
        locals: { my_bookings: booking.passenger.bookings }
      )
    end

    # Broadcast to driver
    Turbo::StreamsChannel.broadcast_replace_to(
      "user_#{driver.user_id}_dashboard",
      target: "rides_content",
      partial: "dashboard/rides_content",
      locals: {
        my_bookings: bookings,
        active_rides: driver.rides.active,
        pending_bookings: Booking.pending,
        past_rides: driver.rides.past
      }
    )
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
end
