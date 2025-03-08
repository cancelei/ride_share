class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @tab = params[:tab] || "active"
    @expanded = params[:expanded]

    # Initialize @my_bookings as an empty array by default
    @my_bookings = []

    case @user.role
    when "driver"
      @driver_profile = @user.driver_profile
      @current_vehicle = @driver_profile&.selected_vehicle
      @pending_bookings = Booking.pending
      @active_rides = @driver_profile ? Ride.where(driver: @driver_profile).active : []
      @history_rides = @driver_profile ? Ride.where(driver: @driver_profile).history : []
      @past_rides = @driver_profile ? Ride.where(driver: @driver_profile, status: :completed).order(created_at: :desc).limit(5) : []
      @last_week_rides_total = @past_rides.total_estimated_price_for_last_week
      @monthly_rides_total = @past_rides.total_estimated_price_for_last_thirty_days
    when "passenger"
      @passenger_profile = @user.passenger_profile
      if @passenger_profile
        @my_bookings = Booking.where(passenger: @passenger_profile, status: :pending).order(scheduled_time: :desc)

        @active_rides = Ride.active.includes(bookings: :locations).where(bookings: { passenger: current_user.passenger_profile })
        @history_rides = Ride.history.includes(bookings: :locations).where(bookings: { passenger: current_user.passenger_profile })
      end
    when "admin"
      @total_users = User.count
      @total_drivers = DriverProfile.count
      @total_passengers = PassengerProfile.count
      @total_rides = Ride.with_discarded.count
      @active_rides = Ride.kept.count
      @total_bookings = Booking.with_discarded.count
      @active_bookings = Booking.kept.count
      @recent_bookings = Booking.with_discarded.order(created_at: :desc).limit(10)
    else
      redirect_to root_path, alert: "Invalid user role"
      return
    end

    render "dashboard/show"
  end

  def rides
    @tab = params[:tab] || "active"

    if current_user.passenger_profile
      @my_bookings = Booking.where(passenger: @passenger_profile, status: :pending).order(scheduled_time: :desc)

      @active_rides = Ride.active.includes(bookings: :locations).where(bookings: { passenger: current_user.passenger_profile })
      @history_rides = Ride.history.includes(bookings: :locations).where(bookings: { passenger: current_user.passenger_profile })
    elsif current_user.driver_profile
      @pending_bookings = Booking.pending

      @active_rides = current_user.driver_profile.rides.active
      @history_rides = current_user.driver_profile.rides.history
    else
      @active_rides = []
      @history_rides = []
    end

    render partial: "dashboard/rides_content"
  end

  def index
    @tab = params[:tab]

    if current_user.driver_profile
      @pending_bookings = Booking.pending

      @active_rides = current_user.driver_profile.rides.active
      @history_rides = current_user.driver_profile.rides.history
    elsif current_user.passenger_profile
      @my_bookings = Booking.where(passenger: @passenger_profile, status: :pending).order(scheduled_time: :desc)

      @active_rides = Ride.active.includes(bookings: :locations).where(bookings: { passenger: current_user.passenger_profile })
      @history_rides = Ride.history.includes(bookings: :locations).where(bookings: { passenger: current_user.passenger_profile })
    else
      @active_rides = []
      @history_rides = []
    end

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def expand_ride
    @ride = Ride.find(params[:ride_id])
    @expanded = params[:expanded]

    # Prepare the data for the view
    @ride_data = {
      id: @ride.id,
      pickup_location: format_location(@ride.bookings.first&.pickup_location),
      dropoff_location: format_location(@ride.bookings.first&.dropoff_location),
      scheduled_date: @ride.bookings.first&.scheduled_time&.strftime("%A, %B %d, %Y"),
      scheduled_time: @ride.bookings.first&.scheduled_time&.strftime("%I:%M %p"),
      estimated_duration: @ride.respond_to?(:estimated_duration) ? @ride.estimated_duration : 15,
      distance: @ride.respond_to?(:distance) && @ride.distance ? @ride.distance : 12.5,
      estimated_price: @ride.estimated_price || 0,
      status: @ride.status
    }

    respond_to do |format|
      format.html { redirect_to dashboard_path(expanded: @expanded) }
      format.turbo_stream
      format.js # Add JavaScript format for older AJAX requests
      # Fallback for any other format
      format.any { redirect_to dashboard_path(expanded: @expanded) }
    end
  end

  private

  def format_location(location)
    if location.is_a?(String)
      location
    elsif location.respond_to?(:address)
      location.address
    elsif location.respond_to?(:to_s)
      location.to_s
    else
      "Location not available"
    end
  end
end
