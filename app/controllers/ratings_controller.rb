class RatingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ride, only: [ :new, :create ]

  def new
    @rating = Rating.new

    # Determine who is rating whom
    if @ride.passenger.user == current_user
      # Passenger rating driver
      @rater = @ride.passenger
      @rateable = @ride.driver
    elsif @ride.driver.user == current_user
      # Driver rating passenger
      @rater = @ride.driver
      @rateable = @ride.passenger
    else
      redirect_to root_path, alert: "You're not authorized to rate this ride."
      return
    end

    # Check if the user has already rated for this ride
    if Rating.exists?(rater: @rater, rateable: @rateable)
      redirect_to dashboard_path, notice: "You've already rated this participant for this ride."
      nil
    end
  end

  def create
    @rating = Rating.new(rating_params)

    # Determine who is being rated
    if @ride.passenger.user == current_user
      # Passenger rating driver
      @rater = @ride.passenger
      @rateable = @ride.driver
    elsif @ride.driver.user == current_user
      # Driver rating passenger
      @rater = @ride.driver
      @rateable = @ride.passenger
    else
      redirect_to root_path, alert: "You're not authorized to rate this ride."
      return
    end

    @rating.rater = @rater
    @rating.rateable = @rateable

    respond_to do |format|
      if @rating.save
        # Also create a rating for the ride itself
        ride_rating = Rating.new(
          score: @rating.score,
          comment: @rating.comment,
          rater: @rater,
          rateable: @ride
        )

        # If we can't save the ride rating, log it but don't fail the whole process
        unless ride_rating.save
          Rails.logger.error "Failed to save ride rating: #{ride_rating.errors.full_messages.join(', ')}"
        end

        # Check if both driver and passenger have rated
        driver_rated = Rating.exists?(rater_type: "DriverProfile", rater_id: @ride.driver.id, rateable: @ride.passenger)
        passenger_rated = Rating.exists?(rater_type: "PassengerProfile", rater_id: @ride.passenger.id, rateable: @ride.driver)

        # If both have rated, update the ride status to completed
        if driver_rated && passenger_rated
          @ride.update(status: :completed)
        end

        format.html { redirect_to dashboard_path, notice: "Thank you for your rating!" }
        format.turbo_stream {
          flash.now[:notice] = "Thank you for your rating!"
          render turbo_stream: [
            turbo_stream.replace("flash", partial: "shared/flash"),
            turbo_stream.replace("ride_#{@ride.id}", partial: "rides/ride_card", locals: { ride: @ride, current_user: current_user })
          ]
        }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "rating_form",
            partial: "ratings/form",
            locals: { rating: @rating, ride: @ride }
          )
        }
      end
    end
  end

  private

  def set_ride
    @ride = Ride.find(params[:ride_id])

    # Verify if the ride is in the rating_required status
    unless @ride.rating_required?
      redirect_to root_path, alert: "This ride is not ready for rating."
    end
  end

  def rating_params
    params.require(:rating).permit(:score, :comment)
  end
end
