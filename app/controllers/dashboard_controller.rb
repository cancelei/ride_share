class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user

    case @user.role
    when "driver"
      @driver_profile = @user.driver_profile
      @current_vehicle = @driver_profile&.selected_vehicle
      @pending_rides = Ride.where(status: :pending)
      @active_rides = Ride.where(driver: @driver_profile, status: [ :accepted, :in_progress ])
      @past_rides = Ride.where(driver: @driver_profile, status: :completed).order(created_at: :desc).limit(5)
      @last_week_rides_total = @past_rides.total_estimated_price_for_last_week
      @monthly_rides_total = @past_rides.total_estimated_price_for_last_thirty_days
    when "passenger"
      @passenger_profile = @user.passenger_profile
      @my_rides = Ride.where(passenger: @passenger_profile).order(scheduled_time: :desc).limit(5)
      @past_rides = @my_rides.where(status: :completed).order(created_at: :desc).limit(5)
    when "admin"
      @total_users = User.with_discarded.count
      @active_users = User.kept.count
      @total_rides = Ride.with_discarded.count
      @active_rides = Ride.kept.count
      @recent_rides = Ride.with_discarded.order(created_at: :desc).limit(10)
    else
      redirect_to root_path, alert: "Invalid user role"
    end

    render "dashboard/show"
  end

  def passenger_rides
    @user = current_user
    @passenger_profile = @user.passenger_profile

    # Convert params[:type] to string to ensure consistent comparison
    tab_type = params[:type].to_s

    # Get all rides for this passenger
    @my_rides = Ride.where(passenger: @passenger_profile).order(scheduled_time: :desc)

    # Filter rides based on tab type
    case tab_type
    when "history"
      @filtered_rides = @my_rides.where(status: [ :completed, :cancelled ])
    else # "active" or any other value
      @filtered_rides = @my_rides.where(status: [ :pending, :accepted, :in_progress ])
      tab_type = "active" # Ensure we have a valid tab type
    end

    # Set up other instance variables needed for the dashboard
    case @user.role
    when "driver"
      @driver_profile = @user.driver_profile
      @current_vehicle = @driver_profile&.selected_vehicle
      @pending_rides = Ride.where(status: :pending)
      @active_rides = Ride.where(driver: @driver_profile, status: [ :accepted, :in_progress ])
      @past_rides = Ride.where(driver: @driver_profile, status: :completed).order(created_at: :desc).limit(5)
      @last_week_rides_total = @past_rides.total_estimated_price_for_last_week
    end

    respond_to do |format|
      format.html do
        # For direct URL access, render the full dashboard
        if turbo_frame_request?
          render partial: "dashboard/turbo_rides_frame", locals: {
            my_rides: @filtered_rides,
            tab_type: tab_type,
            user: @user
          }
        else
          render "dashboard/show"
        end
      end

      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "rides_content",
          partial: "dashboard/rides_content",
          locals: {
            my_rides: @filtered_rides,
            params: { type: tab_type },
            user: @user
          }
        )
      end
    end
  end
end
