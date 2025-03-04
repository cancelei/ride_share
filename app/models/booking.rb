class Booking < ApplicationRecord
  include Discard::Model
  include RideStatusBroadcaster
  include PriceCalculator
  default_scope -> { kept }

  belongs_to :passenger, -> { with_discarded }, class_name: "PassengerProfile", foreign_key: :passenger_id
  belongs_to :ride, -> { with_discarded }, optional: true
  has_many :locations, -> { with_discarded }, dependent: :destroy
  has_one :pickup_location, -> { where(location_type: "pickup") }, class_name: "Location"
  has_one :dropoff_location, -> { where(location_type: "dropoff") }, class_name: "Location"

  before_create :set_status
  before_save :set_estimated_ride_price, if: :ride_id_changed?

  after_update :broadcast_status_update
  after_create :broadcast_status_update
  after_commit :broadcast_update
  after_commit :broadcast_to_drivers, on: :create
  after_commit :broadcast_cancellation, if: -> { saved_change_to_status? && status == "cancelled" }
  after_create :send_booking_confirmation
  after_update :send_status_update_emails
  after_create :send_notification_to_drivers

  Rails.logger.info "Booking model loaded with callbacks: #{_commit_callbacks.map(&:filter)}"

  def set_estimated_ride_price
    return unless ride_id.present?

    total_distance = Booking.where(ride_id: ride_id)
                           .pluck(:distance_km)
                           .sum + (distance_km || 0)

    total_price = (3.5 + total_distance * 2).round(2)
    ride.update_column(:estimated_price, total_price)
  end

  enum :status, { pending: "pending", accepted: "accepted", in_progress: "in_progress", rejected: "rejected", completed: "completed", cancelled: "cancelled" }, prefix: true

  accepts_nested_attributes_for :locations

  scope :active, -> { where(status: [ "pending", "accepted", "in_progress" ]) }
  scope :pending, -> { where(status: "pending") }
  scope :past, -> { where(status: [ "completed" ]) }
  scope :cancelled, -> { where(status: "cancelled") }
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

  def send_notification_to_drivers
    Rails.logger.info "Starting send_notification_to_drivers for booking #{id}"
    
    # Get all pending bookings except the current one - convert to array to avoid serialization issues
    other_pending_bookings = Booking.pending.where.not(id: self.id).limit(5).to_a
    Rails.logger.info "Found #{other_pending_bookings.count} other pending bookings"
    
    # Count eligible drivers
    eligible_drivers = User.role_driver.select { |driver| driver.driver_profile&.vehicles&.any? }
    Rails.logger.info "Found #{eligible_drivers.count} eligible drivers with vehicles"
    
    # Send email to each driver
    eligible_drivers.each do |driver|
      begin
        Rails.logger.info "Attempting to send email for driver: #{driver.id} (#{driver.email})"
        # Use deliver_later with GlobalID serialization
        UserMailer.new_booking_notification(self, driver, other_pending_bookings).deliver_later
        Rails.logger.info "Successfully queued email for driver: #{driver.id} (#{driver.email})"
      rescue => e
        Rails.logger.error "Failed to send email for driver #{driver.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end
    
    Rails.logger.info "Completed send_notification_to_drivers for booking #{id}"
  rescue => e
    Rails.logger.error "Error in send_notification_to_drivers: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  def self.check_callbacks
    Rails.logger.info "Checking Booking model callbacks..."
    
    create_callbacks = _commit_callbacks.select { |cb| cb.kind == :create }
    Rails.logger.info "Create callbacks: #{create_callbacks.map(&:filter)}"
    
    after_create_callbacks = _commit_callbacks.select { |cb| cb.kind == :create && cb.name == :after }
    Rails.logger.info "After create callbacks: #{after_create_callbacks.map(&:filter)}"
    
    # Check if our specific method is in the callbacks
    has_notification_callback = after_create_callbacks.any? { |cb| cb.filter.to_s.include?('send_notification_to_drivers') }
    Rails.logger.info "Has send_notification_to_drivers callback: #{has_notification_callback}"
    
    return {
      create_callbacks: create_callbacks.map(&:filter),
      after_create_callbacks: after_create_callbacks.map(&:filter),
      has_notification_callback: has_notification_callback
    }
  end
end
