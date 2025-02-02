class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user

    case @user.role
    when "driver"
      @driver_profile = @user.driver_profile
      @current_vehicle = @driver_profile&.selected_vehicle
      @pending_bookings = Booking.where(status: :pending)
      @active_rides = Ride.where(driver: @driver_profile, status: [ :accepted, :ongoing ])
      @past_rides = Ride.where(driver: @driver_profile, status: :completed).order(created_at: :desc).limit(5)
    when "passenger"
      @passenger_profile = @user.passenger_profile
      @my_bookings = Booking.where(passenger: @passenger_profile).order(created_at: :desc).limit(5)
      @past_rides = Ride.where(passenger: @passenger_profile).order(created_at: :desc).limit(5)
      @my_rides = Ride.joins(:bookings)
                      .where(bookings: { passenger: @passenger_profile })
                      .order(created_at: :desc)
                      .limit(5)
      @shared_bookings = Booking.includes(:ride)
                               .where(passenger: @passenger_profile)
                               .order(scheduled_time: :desc)
    when "admin"
      @total_users = User.count
      @total_rides = Ride.count
      @total_bookings = Booking.count
      @recent_bookings = Booking.order(created_at: :desc).limit(10)
    end

    if current_user.driver_profile
      @driver_rides = Ride.includes(:bookings)
                         .where(driver: @driver_profile)
                         .order(created_at: :desc)
    end
  end

  def rides
    @my_bookings = current_user.passenger_profile.bookings
    render partial: "dashboard/rides_content"
  end
end
