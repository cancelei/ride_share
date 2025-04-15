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
      @ride.update(status: :completed)
      redirect_to dashboard_path, notice: "Ride Completed! No rating required for self-rides."
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
    rater, @rateable, current_role = get_roles

    # # Only block if a rating exists for this rater/rateable for THIS ride
    # if rating_exist?(rater, @rateable.class.name)
    #   redirect_to dashboard_path, notice: "You've already rated this participant for this ride."
    #   nil
    # end
  end

  def create
    @rating = Rating.new
    @roles = []
    @role = params[:role]
    @roles << :passenger if @ride.passenger.user == current_user
    @roles << :driver if @ride.driver.user == current_user

    if @roles.empty?
      redirect_to root_path, alert: "You're not authorized to rate this ride."
      return
    end

    # Accept and trust the role param if user owns both profiles
    rater, @rateable, current_role = get_roles


    @rating.rateable_type = @rateable.class.name
    @rating.rateable_id = @rateable.id
    @rating.rater_type = rater.class.name
    @rating.rater_id = rater.id
    @rating.ride_id = @ride.id
    @rating.score = rating_params[:score]
    @rating.comment = rating_params[:comment]
    @rating.rater = rater
    @rating.rateable = @rateable

    puts "======================================"
    puts @rating.inspect
    puts "======================================"

    if @rating.save
      driver_rated = rating_exist?(rater, rateable_type = "DriverProfile")
      passenger_rated = rating_exist?(rater, rateable_type = "PassengerProfile")
      puts "Driver Rated: #{driver_rated}"
      puts "Passenger Rated: #{passenger_rated}"
      if driver_rated && passenger_rated
        @ride.update(status: :completed)
      end
      redirect_to dashboard_path, notice: "Thank you for your rating!"
    else
      respond_to do |format|
        # Ensure rateable and @current_role are set for the form partial
        rater, rateable, current_role = get_roles
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "rating_form",
            partial: "ratings/form",
            locals: { rating: @rating, ride: @ride, rateable: rateable, role: current_role }
          )
        }
      end
    end
  end

  private

  def set_ride
    @ride = Ride.find(params[:ride_id])
  end

  def rating_params
    params.require(:rating).permit(:score, :comment)
  end

  def get_roles
    if @roles.include?(:passenger) && @role == "passenger"
      [ @ride.passenger, @ride.driver, :passenger ]
    elsif @roles.include?(:driver) && @role == "driver"
      [ @ride.driver, @ride.passenger, :driver ]
    elsif @roles.size == 1 && @roles.include?(:passenger)
      [ @ride.passenger, @ride.driver, :passenger ]
    elsif @roles.size == 1 && @roles.include?(:driver)
      [ @ride.driver, @ride.passenger, :driver ]
    else
      redirect_to root_path, alert: "Invalid rating role."
      nil
    end
  end

  def rating_exist?(rater, rateable_type = "PassengerProfile")
    Rating.exists?(rater: rater, rateable: @rateable, rateable_id: @rateable.id, rateable_type: rateable_type, ride_id: @ride.id)
  end
end
