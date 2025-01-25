require "net/http"
require "uri"
require "json"

class Ride < ApplicationRecord
  belongs_to :driver, class_name: "DriverProfile", foreign_key: :driver_id
  has_many :bookings

  before_create :set_status
  before_save :save_participants
  after_save :update_booking, -> { booking_id.present? }

  attr_accessor :booking_id

  enum :status, { accepted: "accepted", ongoing: "ongoing", completed: "completed" }

  scope :active, -> { where("start_time >= ?", Time.current) }
  scope :past, -> { where("start_time < ?", Time.current) }

  def set_status
    self.status = "accepted"
  end

  def update_booking
    Booking.where(id: self.booking_id).update_all(status: "accepted", ride_id: self.id)

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
    origin = "My+Location"
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

  def save_participants
    self.participants_count = bookings.sum(:requested_seats)
  end
end
