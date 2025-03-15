class RidesController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show, :test_emails ]
  before_action :set_ride, only: %i[ show edit update destroy start finish accept mark_as_paid ]
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
    @ride = Ride.find(params[:id])

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
    Rails.logger.debug "RIDE DEBUG: Initial ride params: #{ride_params.inspect}"
    Rails.logger.debug "RIDE DEBUG: Initial ride status: #{@ride.status.inspect}"

    if current_user&.role_passenger?
      # Set passenger to current user's passenger profile
      @ride.passenger = current_user.passenger_profile
      @ride.status = "pending"
      Rails.logger.debug "RIDE DEBUG: After setting passenger status: #{@ride.status.inspect}"

      # Calculate estimated price based on distance
      @ride.calculate_price if @ride.pickup_location.present? && @ride.dropoff_location.present?
    elsif current_user&.role_driver?
      # Set driver to current user's driver profile
      @ride.driver = current_user.driver_profile
      Rails.logger.debug "RIDE DEBUG: After setting driver: #{@ride.status.inspect}"

      # Set vehicle from params
      if params[:vehicle_id].present?
        @vehicle = Vehicle.find(params[:vehicle_id])
        @ride.vehicle = @vehicle
        Rails.logger.debug "RIDE DEBUG: After setting vehicle: #{@ride.status.inspect}"
      end
    end

    Rails.logger.debug "RIDE DEBUG: Before save, status: #{@ride.status.inspect}"

    respond_to do |format|
      if @ride.save
        Rails.logger.debug "RIDE DEBUG: After save, status: #{@ride.status.inspect}"
        Rails.logger.debug "RIDE DEBUG: Ride attributes: #{@ride.attributes.inspect}"

        format.html { redirect_to dashboard_path, notice: "Ride was successfully requested." }
        format.json { render :show, status: :created, location: @ride }
        format.turbo_stream { redirect_to dashboard_path, notice: "Ride was successfully requested." }
      else
        Rails.logger.debug "RIDE DEBUG: Save failed, errors: #{@ride.errors.full_messages.inspect}"

        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ride.errors, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("new_ride", partial: "rides/passenger_form", locals: { ride: @ride }) }
      end
    end
  end

  # PATCH/PUT /rides/1 or /rides/1.json
  def update
    respond_to do |format|
      if @ride.update(ride_params)
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
    @ride = Ride.find(params[:id])

    if current_user&.role_driver?
      @ride.driver = current_user.driver_profile
      @ride.vehicle = current_user.driver_profile.selected_vehicle
      @ride.status = :accepted

      if @ride.save
        # Instead of triggering the broadcast directly, we'll manually broadcast to the specific channels
        broadcast_ride_acceptance(@ride, current_user)

        redirect_to dashboard_path, notice: "Ride accepted successfully."
      else
        redirect_to dashboard_path, alert: "Failed to accept ride: #{@ride.errors.full_messages.join(', ')}"
      end
    else
      redirect_to dashboard_path, alert: "Only drivers can accept rides."
    end
  end

  # POST /rides/1/start
  def start
    @ride = Ride.find(params[:id])

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
    @ride = Ride.find(params[:id])

    if current_user&.role_driver? && @ride.driver == current_user.driver_profile
      @ride.end_time = Time.current
      @ride.status = :completed

      if @ride.save
        redirect_to ride_path(@ride), notice: "Ride completed successfully."
      else
        redirect_to ride_path(@ride), alert: "Failed to complete ride: #{@ride.errors.full_messages.join(', ')}"
      end
    else
      redirect_to dashboard_path, alert: "You don't have permission to complete this ride."
    end
  end

  def cancel
    @ride = Ride.find(params[:id])

    if current_user&.role_passenger? && @ride.passenger == current_user.passenger_profile
      @ride.status = :cancelled

      if @ride.save
        redirect_to dashboard_path, notice: "Ride cancelled successfully."
      else
        redirect_to ride_path(@ride), alert: "Failed to cancel ride: #{@ride.errors.full_messages.join(', ')}"
      end
    else
      redirect_to dashboard_path, alert: "You don't have permission to cancel this ride."
    end
  end

  # POST /rides/1/verify_security_code
  def verify_security_code
    @ride = Ride.find(params[:id])

    if @ride.security_code == params[:security_code]
      @ride.update(status: "in_progress", start_time: Time.current)

      respond_to do |format|
        format.html { redirect_to @ride, notice: "Ride started successfully!" }
        format.turbo_stream {
          flash.now[:notice] = "Ride started successfully!"

          # Broadcast the status change
          broadcast_ride_acceptance(@ride, current_user)

          render turbo_stream: [
            turbo_stream.replace("ride_#{@ride.id}",
                                partial: "rides/ride_card",
                                locals: { ride: @ride.reload, current_user: current_user }),
            turbo_stream.update("flash", partial: "shared/flash")
          ]
        }
      end
    else
      respond_to do |format|
        format.html { redirect_to @ride, alert: "Invalid security code. Please try again." }
        format.turbo_stream {
          flash.now[:alert] = "Invalid security code. Please try again."
          render turbo_stream.update("flash", partial: "shared/flash")
        }
      end
    end
  end

  # Test email templates (development only)
  def test_emails
    if Rails.env.development?
      @ride = Ride.last

      case params[:email_type]
      when "confirmation"
        UserMailer.ride_confirmation(@ride).deliver_now
      when "accepted"
        UserMailer.ride_accepted(@ride).deliver_now
      when "driver_arrived"
        UserMailer.driver_arrived(@ride).deliver_now
      when "completion_passenger"
        UserMailer.ride_completion_passenger(@ride).deliver_now
      when "completion_driver"
        UserMailer.ride_completion_driver(@ride).deliver_now
      else
        render plain: "Invalid email type"
        return
      end

      render plain: "Email sent: #{params[:email_type]}"
    else
      render plain: "Only available in development"
    end
  end

  # GET /rides/1/driver_location
  def driver_location
    @ride = Ride.find(params[:id])

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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ride
      @ride = Ride.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ride_params
      params.require(:ride).permit(
        :pickup_location, :dropoff_location, :scheduled_time,
        :status, :start_time, :end_time, :driver_id, :vehicle_id,
        :passenger_id, :requested_seats, :special_instructions,
        :pickup_lat, :pickup_lng, :dropoff_lat, :dropoff_lng,
        :pickup_address, :dropoff_address,
        :distance_km, :estimated_duration_minutes, :total_travel_duration_minutes
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
