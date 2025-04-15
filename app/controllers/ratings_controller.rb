class RatingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ride, only: [ :new, :create ]

  def new
    @rating = Rating.new
    @roles = []
    @role = params[:role]
    # Determine available roles for current user
    # Skip rating if self-ride
    if @ride.driver.user == @ride.passenger.user
      redirect_to dashboard_path, notice: "No rating required for self-rides."
      return
    end
    @roles << :passenger if @ride.passenger.user == current_user
    @roles << :driver if @ride.driver.user == current_user

    if @roles.empty?
      redirect_to root_path, alert: "You're not authorized to rate this ride."
      return
    end

    # If user has both roles and no role param, show a selector or both forms
    if @roles.size > 1 && @role.blank?
      # Let the view handle showing both forms
      return
    end

    # Pick the correct rater/rateable based on role
    # Accept and trust the role param if user owns both profiles
    if @roles.include?(:passenger) && @role == "passenger"
      @rater = @ride.passenger
      @rateable = @ride.driver
      @current_role = :passenger
    elsif @roles.include?(:driver) && @role == "driver"
      @rater = @ride.driver
      @rateable = @ride.passenger
      @current_role = :driver
    elsif @roles.size == 1 && @roles.include?(:passenger)
      @rater = @ride.passenger
      @rateable = @ride.driver
      @current_role = :passenger
    elsif @roles.size == 1 && @roles.include?(:driver)
      @rater = @ride.driver
      @rateable = @ride.passenger
      @current_role = :driver
    else
      redirect_to root_path, alert: "Invalid rating role."
      return
    end

    # Only block if a rating exists for this rater/rateable for THIS ride
    if Rating.exists?(rater: @rater, rateable: @rateable, rateable_id: @rateable.id, rateable_type: @rateable.class.name, ride_id: @ride.id)
      redirect_to dashboard_path, notice: "You've already rated this participant for this ride."
      nil
    end
  end

  def create
    @rating = Rating.new(rating_params)
    @roles = []
    @role = params[:role]
    # Skip rating if self-ride
    if @ride.driver.user == @ride.passenger.user
      redirect_to dashboard_path, notice: "No rating required for self-rides."
      return
    end
    @roles << :passenger if @ride.passenger.user == current_user
    @roles << :driver if @ride.driver.user == current_user

    if @roles.empty?
      redirect_to root_path, alert: "You're not authorized to rate this ride."
      return
    end

    # Accept and trust the role param if user owns both profiles
    if @roles.include?(:passenger) && @role == "passenger"
      @rater = @ride.passenger
      @rateable = @ride.driver
      @current_role = :passenger
    elsif @roles.include?(:driver) && @role == "driver"
      @rater = @ride.driver
      @rateable = @ride.passenger
      @current_role = :driver
    elsif @roles.size == 1 && @roles.include?(:passenger)
      @rater = @ride.passenger
      @rateable = @ride.driver
      @current_role = :passenger
    elsif @roles.size == 1 && @roles.include?(:driver)
      @rater = @ride.driver
      @rateable = @ride.passenger
      @current_role = :driver
    else
      redirect_to root_path, alert: "Invalid rating role."
      return
    end

    # Only block if a rating exists for this rater/rateable for THIS ride
    if Rating.exists?(rater: @rater, rateable: @rateable, rateable_id: @rateable.id, rateable_type: @rateable.class.name, ride_id: @ride.id)
      redirect_to dashboard_path, notice: "You've already rated this participant for this ride."
      return
    end

    @rating.rater = @rater
    @rating.rateable = @rateable

    respond_to do |format|
      if @rating.save
        ride_rating = Rating.new(
          score: @rating.score,
          comment: @rating.comment,
          rater: @rater,
          rateable: @ride
        )
        unless ride_rating.save
          Rails.logger.error "Failed to save ride rating: #{ride_rating.errors.full_messages.join(', ')}"
        end

        driver_rated = Rating.exists?(rater_type: "DriverProfile", rater_id: @ride.driver.id, rateable: @ride.passenger)
        passenger_rated = Rating.exists?(rater_type: "PassengerProfile", rater_id: @ride.passenger.id, rateable: @ride.driver)
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
        # Ensure @rateable and @current_role are set for the form partial
        if @roles.include?(:passenger) && @role == "passenger"
          @rateable = @ride.driver
          @current_role = :passenger
        elsif @roles.include?(:driver) && @role == "driver"
          @rateable = @ride.passenger
          @current_role = :driver
        elsif @roles.size == 1 && @roles.include?(:passenger)
          @rateable = @ride.driver
          @current_role = :passenger
        elsif @roles.size == 1 && @roles.include?(:driver)
          @rateable = @ride.passenger
          @current_role = :driver
        end
        format.html { render :new, status: :unprocessable_entity }
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
