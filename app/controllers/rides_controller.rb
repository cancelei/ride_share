class RidesController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_ride, only: %i[ show edit update destroy start finish accept mark_as_paid complete cancel verify_security_code driver_location arrived_at_pickup ]
  before_action :check_driver_requirements, only: %i[ new create ], if: -> { current_user&.role_driver? }
  before_action :ensure_passenger_profile, only: %i[ new create ], if: -> { current_user&.role_passenger? }

  # GET /rides or /rides.json
  def index
    if current_user&.role_driver?
      @active_rides = Ride.includes(:driver, :passenger)
                         .where(driver: current_user.driver_profile)
                         .where(status: [ :pending, :accepted, :in_progress ])
                         .order(created_at: :desc)
                         .distinct

      @past_rides = Ride.includes(:driver, :passenger)
                       .where(driver: current_user.driver_profile)
                       .where(status: [ :completed, :cancelled ])
                       .order(created_at: :desc)
                       .distinct
    elsif current_user&.role_passenger?
      @active_rides = Ride.where(passenger: current_user.passenger_profile)
                         .where(status: [ :pending, :accepted, :in_progress ])
                         .order(created_at: :desc)

      @past_rides = Ride.where(passenger: current_user.passenger_profile)
                       .where(status: [ :completed, :cancelled ])
                       .order(created_at: :desc)
    else
      @rides = Ride.all.order(created_at: :desc)
    end
  end

  # GET /rides/1 or /rides/1.json
  def show
    respond_to do |format|
      format.html
      format.turbo_stream do
        if params[:expanded] == "true"
          render turbo_stream: turbo_stream.update("ride_details_#{@ride.id}", partial: "rides/ride_details", locals: { ride: @ride })
        else
          render turbo_stream: turbo_stream.update("ride_details_#{@ride.id}", "")
        end
      end
      format.json { render :show, status: :ok, location: @ride }
    end
  end

  # GET /rides/new
  def new
    if params[:user_id].present? && current_user.role_driver?
      redirect_to dashboard_path, notice: "You cannot create a ride as a Driver."
    end

    @ride = Ride.new

    if current_user&.role_driver? && current_user.driver_profile.nil?
      redirect_to new_driver_profile_path, notice: "Please create a driver profile first."
    elsif current_user&.role_passenger? && current_user.passenger_profile.nil?
      redirect_to new_passenger_profile_path, notice: "Please create a passenger profile first."
    end
  end

  # GET /rides/1/edit
  def edit
  end

  # POST /rides or /rides.json
  def create
    @ride = Ride.new(ride_params)
    @ride.passenger = current_user.passenger_profile
    @ride.status = "pending"

    # Handle pickup location from Google Places API V1 response
    if params[:ride][:pickup_location].present?
      @ride.pickup_location = params[:ride][:pickup_location]
      @ride.pickup_address = params[:ride][:pickup_address]
    end

    if params[:ride][:dropoff_location].present?
      @ride.dropoff_location = params[:ride][:dropoff_location]
      @ride.dropoff_address = params[:ride][:dropoff_address]
    end

    # Set coordinates and calculate price
    @ride.pickup_lat = params[:ride][:pickup_lat]
    @ride.pickup_lng = params[:ride][:pickup_lng]
    @ride.dropoff_lat = params[:ride][:dropoff_lat]
    @ride.dropoff_lng = params[:ride][:dropoff_lng]
    @ride.distance_km = params[:ride][:distance_km]
    @ride.estimated_price = params[:ride][:estimated_price]

    Rails.logger.debug "RIDE DEBUG: Initial ride params: #{ride_params.inspect}"
    Rails.logger.debug "RIDE DEBUG: Coordinates: pickup=(#{@ride.pickup_lat},#{@ride.pickup_lng}), dropoff=(#{@ride.dropoff_lat},#{@ride.dropoff_lng})"
    Rails.logger.debug "RIDE DEBUG: Distance and Price: distance=#{@ride.distance_km}km, price=$#{@ride.estimated_price}"

    respond_to do |format|
      if @ride.save
        format.html { redirect_to dashboard_path, notice: "Ride was successfully created." }
        format.json { render :show, status: :created, location: @ride }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ride.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /rides/1 or /rides/1.json
  def update
    respond_to do |format|
      # Update display names if provided
      ride_update_params = ride_params
      ride_update_params[:pickup_location] = params[:ride][:pickup_location] if params[:ride][:pickup_location].present?
      ride_update_params[:dropoff_location] = params[:ride][:dropoff_location] if params[:ride][:dropoff_location].present?

      if @ride.update(ride_update_params)
        format.html { redirect_to ride_url(@ride), notice: "Ride was successfully updated." }
        format.json { render :show, status: :ok, location: @ride }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ride.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /rides/1 or /rides/1.json
  def destroy
    @ride.destroy

    respond_to do |format|
      format.html { redirect_to rides_url, notice: "Ride was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # POST /rides/1/accept
  def accept
    if current_user&.role_driver?
      Rails.logger.debug "RIDE ACCEPT: Driver #{current_user.id} attempting to accept ride #{@ride.id}"

      # Verify the ride is in a pending state
      if @ride.status != "pending"
        Rails.logger.debug "RIDE ACCEPT: Failed - Ride #{@ride.id} is not pending (status: #{@ride.status})"
        redirect_to dashboard_path, alert: "This ride cannot be accepted because it is not pending."
        return
      end

      if current_user.driver_profile.nil?
        Rails.logger.debug "RIDE ACCEPT: Failed - Driver #{current_user.id} has no driver profile"
        redirect_to dashboard_path, alert: "You need to create a driver profile before accepting rides."
        return
      end

      # Check if driver has a selected vehicle
      if current_user.driver_profile.selected_vehicle.nil?
        Rails.logger.debug "RIDE ACCEPT: Failed - Driver #{current_user.id} has no selected vehicle"
        redirect_to dashboard_path, alert: "You need to select a vehicle before accepting rides."
        return
      end

      @ride.driver = current_user.driver_profile
      @ride.vehicle = current_user.driver_profile.selected_vehicle
      @ride.status = :accepted

      Rails.logger.debug "RIDE ACCEPT: Attempting to save ride #{@ride.id} with driver #{@ride.driver_id} and vehicle #{@ride.vehicle_id}"

      if @ride.save
        Rails.logger.debug "RIDE ACCEPT: Success - Ride #{@ride.id} accepted by driver #{@ride.driver_id}"
        # Instead of triggering the broadcast directly, we'll manually broadcast to the specific channels
        broadcast_ride_acceptance(@ride, current_user)

        redirect_to dashboard_path, notice: "Ride accepted successfully."
      else
        Rails.logger.debug "RIDE ACCEPT: Failed to save - Errors: #{@ride.errors.full_messages.inspect}"
        redirect_to dashboard_path, alert: "Failed to accept ride: #{@ride.errors.full_messages.join(', ')}"
      end
    else
      Rails.logger.debug "RIDE ACCEPT: Failed - User #{current_user.id} is not a driver"
      redirect_to dashboard_path, alert: "Only drivers can accept rides."
    end
  end

  # POST /rides/1/start
  def start
    if current_user&.role_driver? && @ride.driver == current_user.driver_profile
      @ride.start_time = Time.current
      @ride.status = :in_progress

      if @ride.save
        redirect_to ride_path(@ride), notice: "Ride started successfully."
      else
        redirect_to ride_path(@ride), alert: "Failed to start ride: #{@ride.errors.full_messages.join(', ')}"
      end
    else
      redirect_to dashboard_path, alert: "You don't have permission to start this ride."
    end
  end

  # POST /rides/1/finish
  def finish
    if @ride.can_complete? && @ride.driver == current_user.driver_profile
      if @ride.finish!
        redirect_to ride_path(@ride), notice: "Ride completed successfully."
      else
        redirect_to ride_path(@ride), alert: "Failed to complete ride: #{@ride.errors.full_messages.join(', ')}"
      end
    else
      redirect_to dashboard_path, alert: "You cannot finish this ride."
    end
  end

  # PATCH /rides/1/mark_as_paid
  def mark_as_paid
    if @ride.mark_paid!
      respond_to do |format|
        format.html { redirect_to dashboard_path, notice: "Payment status updated." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to dashboard_path, alert: "Failed to update payment status." }
        format.turbo_stream
      end
    end
  end

  def complete
    if current_user&.role_driver? && @ride.driver == current_user.driver_profile
      @ride.end_time = Time.current
      @ride.status = :completed

      if @ride.save
        set_flash(:notice, "Ride completed successfully.")
        redirect_to ride_path(@ride)
      else
        set_flash(:alert, "Failed to complete ride: #{@ride.errors.full_messages.join(', ')}")
        redirect_to ride_path(@ride)
      end
    else
      set_flash(:alert, "You don't have permission to complete this ride.")
      redirect_to dashboard_path
    end
  end

  def cancel
    if (current_user&.role_passenger? && @ride.passenger == current_user.passenger_profile) ||
       (current_user&.role_driver? && @ride.driver == current_user.driver_profile && @ride.can_be_cancelled_by_driver?)

      @ride.status = :cancelled
      @ride.cancellation_reason = params[:cancellation_reason]
      @ride.cancelled_by = current_user.role

      if @ride.save
        set_flash(:notice, "Ride cancelled successfully.")

        respond_to do |format|
          format.html { redirect_to dashboard_path }
          format.turbo_stream {
            render turbo_stream: [
              turbo_stream.replace("ride_#{@ride.id}",
                partial: "rides/ride_card",
                locals: { ride: @ride.reload, current_user: current_user }
              ),
              render_flash_turbo_stream
            ]
          }
        end
      else
        error_message = "Failed to cancel ride: #{@ride.errors.full_messages.join(', ')}"
        set_flash(:alert, error_message)

        respond_to do |format|
          format.html { redirect_to ride_path(@ride) }
          format.turbo_stream { render turbo_stream: render_flash_turbo_stream }
        end
      end
    else
      set_flash(:alert, "You don't have permission to cancel this ride.")

      respond_to do |format|
        format.html { redirect_to dashboard_path }
        format.turbo_stream { render turbo_stream: render_flash_turbo_stream }
      end
    end
  end

  # POST /rides/1/verify_security_code
  def verify_security_code
    if @ride.security_code == params[:security_code]
      @ride.update(status: "in_progress", start_time: Time.current)

      set_flash(:notice, "Ride started successfully!")

      respond_to do |format|
        format.html { redirect_to @ride }
        format.turbo_stream {
          # Broadcast the status change
          broadcast_ride_acceptance(@ride, current_user)

          render turbo_stream: [
            turbo_stream.replace("ride_#{@ride.id}",
                            partial: "rides/ride_card",
                            locals: { ride: @ride.reload, current_user: current_user }),
            render_flash_turbo_stream
          ]
        }
      end
    else
      set_flash(:alert, "Invalid security code. Please try again.")

      respond_to do |format|
        format.html { redirect_to @ride }
        format.turbo_stream { render turbo_stream: render_flash_turbo_stream }
      end
    end
  end

  # GET /rides/1/driver_location
  def driver_location
    # Get the driver's current location
    driver_user = @ride.driver&.user

    if driver_user&.current_location.present?
      location_data = {
        location: {
          address: driver_user.current_location[:address],
          coordinates: driver_user.current_location[:coordinates]
        }
      }

      # Calculate distance and ETA if we have both driver and pickup/dropoff coordinates
      if driver_user.current_location[:coordinates].present? &&
         @ride.pickup_lat.present? && @ride.pickup_lng.present?

        # In a real app, you would use a service like Google Maps Distance Matrix API
        # For now, we'll just provide placeholder values
        location_data[:distance_to_pickup] = "2.5"
        location_data[:eta_minutes] = "10"
      end

      render json: location_data
    else
      render json: { error: "Driver location not available" }, status: :not_found
    end
  end

  # POST /rides/1/arrived_at_pickup
  def arrived_at_pickup
    if current_user&.role_driver? && @ride.driver == current_user.driver_profile

      if @ride.update(status: :waiting_for_passenger_boarding, arrived_time: Time.current)

        # Make sure both driver and passenger get updated UI
        broadcast_ride_acceptance(@ride, current_user)

        set_flash(:notice, "You've marked yourself as arrived. The passenger has been notified.")

        respond_to do |format|
          format.html { redirect_to @ride }
          format.turbo_stream {
            render turbo_stream: [
              turbo_stream.replace("ride_#{@ride.id}",
                partial: "rides/ride_card",
                locals: { ride: @ride.reload, current_user: current_user }
              ),
              render_flash_turbo_stream
            ]
          }
        end
      else
        set_flash(:alert, "Failed to update ride status: #{@ride.errors.full_messages.join(', ')}")

        respond_to do |format|
          format.html { redirect_to @ride }
          format.turbo_stream { render turbo_stream: render_flash_turbo_stream }
        end
      end
    else
      set_flash(:alert, "You don't have permission to perform this action.")

      respond_to do |format|
        format.html { redirect_to dashboard_path }
        format.turbo_stream { render turbo_stream: render_flash_turbo_stream }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ride
      @ride = Ride.find_by(id: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ride_params
      params.require(:ride).permit(
        :pickup_location, :pickup_address, :pickup_lat, :pickup_lng,
        :dropoff_location, :dropoff_address, :dropoff_lat, :dropoff_lng,
        :scheduled_time, :requested_seats, :special_instructions,
        :distance_km, :estimated_price
      )
    end

    def authenticate_user!
      unless current_user
        redirect_to new_user_session_path, alert: "Please sign in to continue."
      end
    end

    def check_driver_requirements
      unless current_user.driver_profile&.vehicles&.exists?
        redirect_to new_driver_profile_vehicle_path(current_user.driver_profile),
          alert: "You need to add a vehicle before creating rides."
      end
    end

    def ensure_passenger_profile
      unless current_user.passenger_profile
        redirect_to new_passenger_profile_path,
          alert: "You need to create a passenger profile before booking rides."
      end
    end

    def broadcast_ride_acceptance(ride, user)
      # Broadcast to passenger
      if ride.passenger.present?
        passenger_user = ride.passenger.user

        # Broadcast to passenger's ride card
        Turbo::StreamsChannel.broadcast_replace_to(
          "user_#{passenger_user.id}_rides",
          target: "ride_#{ride.id}",
          partial: "rides/ride_card",
          locals: {
            ride: ride,
            current_user: passenger_user
          }
        )
      end

      # Broadcast to driver
      if ride.driver.present?
        driver_user = ride.driver.user

        # Broadcast to driver's ride card
        Turbo::StreamsChannel.broadcast_replace_to(
          "user_#{driver_user.id}_rides",
          target: "ride_#{ride.id}",
          partial: "rides/ride_card",
          locals: {
            ride: ride,
            current_user: driver_user
          }
        )
      end
    end
end
