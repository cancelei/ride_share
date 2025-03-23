class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user

    case @user.role
    when "driver"
      tab_type = params[:type].to_s

      @driver_profile = @user.driver_profile
      @current_vehicle = @driver_profile&.selected_vehicle
      @pending_rides = Ride.where(status: :pending)
      @active_rides = Ride.where(driver: @driver_profile, status: [ :accepted, :in_progress ])
      @past_rides = Ride.where(driver: @driver_profile, status: [ :completed, :cancelled ]).order(created_at: :desc).limit(5)
      @last_week_rides_total = @past_rides.total_estimated_price_for_last_week
      @monthly_rides_total = @past_rides.total_estimated_price_for_last_thirty_days

      # Get all rides for display
      all_rides = Ride.where(driver: @driver_profile, status: [ :accepted, :in_progress, :completed, :cancelled ])
      # binding.pry
      # Filter rides based on tab type using helper
      @filtered_rides = helpers.filter_rides_by_tab(all_rides, tab_type)

      # Set the tab_type for the view
      tab_type = "active" unless tab_type == "history"

    when "passenger"
      tab_type = params[:type].to_s

      @passenger_profile = @user.passenger_profile
      all_rides = Ride.where(passenger: @passenger_profile).order(scheduled_time: :desc)

      # Filter rides based on tab type using helper
      @filtered_rides = helpers.filter_rides_by_tab(all_rides, tab_type)

      # Set the tab_type for the view
      tab_type = "active" unless tab_type == "history"

      # Keep these for backwards compatibility
      @my_rides = all_rides.limit(5)
      @past_rides = all_rides.where(status: :completed).order(created_at: :desc).limit(5)
    when "admin"
      @total_users = User.with_discarded.count
      @active_users = User.kept.count
      @total_rides = Ride.with_discarded.count
      @active_rides = Ride.kept.count
      @recent_rides = Ride.with_discarded.order(created_at: :desc).limit(10)
    when "company"
      tab_type = params[:type].to_s

      @company_profile = @user.company_profile

      # Get all drivers associated with this company
      @company_drivers = @company_profile ? DriverProfile.joins(:company_drivers).where(company_drivers: { company_profile_id: @company_profile.id }) : []

      # Get all rides from drivers associated with this company
      driver_ids = @company_drivers.pluck(:id)
      all_rides = Ride.where(driver_id: driver_ids).order(scheduled_time: :desc)

      # Filter rides based on tab type using helper
      @filtered_rides = helpers.filter_rides_by_tab(all_rides, tab_type)

      # Set the tab_type for the view
      tab_type = "active" unless tab_type == "history"

      # Aggregated statistics for the company
      @active_rides = all_rides.where(status: [ :accepted, :in_progress ])
      @completed_rides = all_rides.where(status: :completed)
      @cancelled_rides = all_rides.where(status: :cancelled)

      # Financial stats
      @last_week_rides_total = all_rides.where(status: :completed)
                                        .where("created_at >= ?", 1.week.ago)
                                        .sum(:effective_price)
      @monthly_rides_total = all_rides.where(status: :completed)
                                      .where("created_at >= ?", 30.days.ago)
                                      .sum(:effective_price)
    else
      redirect_to root_path, alert: "Invalid user role"
      return
    end

    render "dashboard/show"
  end

  def user_rides
    @user = current_user

    # Convert params[:type] to string to ensure consistent comparison
    tab_type = params[:type].to_s

    case @user.role
    when "driver"
      @driver_profile = @user.driver_profile
      @current_vehicle = @driver_profile&.selected_vehicle

      # Get all rides for this driver
      all_rides = Ride.where(driver: @driver_profile).order(scheduled_time: :desc)

      # Filter rides based on tab type using helper
      @filtered_rides = helpers.filter_rides_by_tab(all_rides, tab_type)

      # Set the tab_type for the view
      tab_type = "active" unless tab_type == "history"

      # Additional data needed for driver dashboard
      @pending_rides = Ride.where(status: :pending)
      @active_rides = Ride.where(driver: @driver_profile, status: [ :accepted, :in_progress ])
      @past_rides = all_rides.where(status: :completed).order(created_at: :desc).limit(5)
      @last_week_rides_total = @past_rides.total_estimated_price_for_last_week
      @monthly_rides_total = @past_rides.total_estimated_price_for_last_thirty_days

    when "passenger"
      @passenger_profile = @user.passenger_profile

      # Get all rides for this passenger
      all_rides = Ride.where(passenger: @passenger_profile).order(scheduled_time: :desc)

      # Filter rides based on tab type using helper
      @filtered_rides = helpers.filter_rides_by_tab(all_rides, tab_type)

      # Set the tab_type for the view
      tab_type = "active" unless tab_type == "history"

      # Additional data needed for passenger dashboard
      @my_rides = all_rides.limit(5)
      @past_rides = all_rides.where(status: :completed).order(created_at: :desc).limit(5)
    when "company"
      @company_profile = @user.company_profile

      # Get all drivers associated with this company
      @company_drivers = @company_profile ? DriverProfile.joins(:company_drivers).where(company_drivers: { company_profile_id: @company_profile.id }) : []

      # Get all rides from drivers associated with this company
      driver_ids = @company_drivers.pluck(:id)
      all_rides = Ride.where(driver_id: driver_ids).order(scheduled_time: :desc)

      # Filter rides based on tab type using helper
      @filtered_rides = helpers.filter_rides_by_tab(all_rides, tab_type)

      # Set the tab_type for the view
      tab_type = "active" unless tab_type == "history"

      # Aggregated statistics for the company dashboard
      @active_rides = all_rides.where(status: [ :accepted, :in_progress ])
      @completed_rides = all_rides.where(status: :completed)
      @cancelled_rides = all_rides.where(status: :cancelled)

      # Financial statistics
      @last_week_rides_total = all_rides.where(status: :completed)
                                        .where("created_at >= ?", 1.week.ago)
                                        .sum(:effective_price)
      @monthly_rides_total = all_rides.where(status: :completed)
                                      .where("created_at >= ?", 30.days.ago)
                                      .sum(:effective_price)
    else
      redirect_to root_path, alert: "Invalid user role"
      return
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

  # Alias methods for backwards compatibility
  alias_method :passenger_rides, :user_rides
  alias_method :driver_rides, :user_rides
  alias_method :company_rides, :user_rides
end
