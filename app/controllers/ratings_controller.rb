class RatingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ride, only: [ :new, :create ]

  def new
    @rating = Rating.new

    if @ride.driver.user == @ride.passenger.user
      @ride.update(status: :completed)
      redirect_to dashboard_path, notice: "Ride Completed! No rating required for self-rides."
      return
    end

    assign_rater_and_rateable
    nil if check_existing_rating
  end

  def create
    @rating = Rating.new(rating_params)

    respond_to do |format|
      if @rating.save
        complete_ride_if_both_rated

        redirect_to dashboard_path, notice: "Thank you for your rating!", format: :html
      else
        format.html { render :new, status: :unprocessable_entity, notice: "Cannot post rting" }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "rating_form",
            partial: "ratings/form",
            locals: { rating: @rating, ride: @ride, rateable: @rateable, role: @current_role }
          )
        }
      end
    end
  end

  private

  def assign_rater_and_rateable
    if @ride.passenger.user == current_user
      @rater, @rateable = @ride.passenger, @ride.driver
    elsif @ride.driver.user == current_user
      @rater, @rateable = @ride.driver, @ride.passenger
    else
      redirect_to root_path, alert: "Invalid rating role."
    end
  end

  def check_existing_rating
    return false unless Rating.exists?(rater: @rater, rateable: @rateable, ride_id: @ride.id)

    redirect_to dashboard_path, notice: "You've already rated this participant for this ride."
    true
  end

  def complete_ride_if_both_rated
    driver_rated = Rating.exists?(rater_type: "DriverProfile", rater_id: @ride.driver.id, rateable: @ride.passenger)
    passenger_rated = Rating.exists?(rater_type: "PassengerProfile", rater_id: @ride.passenger.id, rateable: @ride.driver)
    @ride.update(status: :completed) if driver_rated && passenger_rated
  end

  def set_ride
    @ride = Ride.find(params[:ride_id] || ride_params[:ride_id])
  end

  def rating_params
    params.require(:rating).permit(:score, :comment, :rateable_type, :rateable_id, :rater_type, :rater_id, :ride_id)
  end
end
