class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user

    case @user.role
    when "driver"
      @driver_profile = @user.driver_profile
      @current_vehicle = @driver_profile&.selected_vehicle
      @pending_bookings = Booking.where(status: :pending)
      @active_rides = Ride.where(driver: @driver_profile, status: [ :pending, :ongoing ])
    when "passenger"
      @passenger_profile = @user.passenger_profile
      @my_bookings = Booking.where(passenger: @passenger_profile).order(created_at: :desc).limit(5)
      @my_rides = Ride.joins(:bookings)
                      .where(bookings: { passenger: @passenger_profile })
                      .order(created_at: :desc)
                      .limit(5)
    when "admin"
      @total_users = User.count
      @total_rides = Ride.count
      @total_bookings = Booking.count
      @recent_bookings = Booking.order(created_at: :desc).limit(10)
    end
  end
end
