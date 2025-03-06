class RidesController < ApplicationController
  before_action :set_ride, only: %i[ show edit update destroy start finish ]
  before_action :check_driver_requirements, only: %i[ new create ]

  # GET /rides or /rides.json
  def index
    @active_rides = Ride.includes(:driver, :bookings)
                       .where(driver: current_user.driver_profile)
                       .where("rides.status IN (?)",
                             [ "pending", "accepted", "ongoing" ])
                       .order("bookings.scheduled_time ASC")
                       .distinct

    @past_rides = Ride.includes(:driver, :bookings)
                     .where(driver: current_user.driver_profile)
                     .where("rides.status IN (?)",
                           [ "completed", "cancelled" ])
                     .order("bookings.scheduled_time DESC")
                     .distinct
  end

  def start
    if params[:security_code].present?
      if @ride.verify_security_code(params[:security_code])
        @ride.start!
        redirect_to dashboard_path, notice: "Ride successfully started."
      else
        redirect_to dashboard_path, alert: "Invalid security code. Please try again."
      end
    else
      redirect_to dashboard_path, alert: "Security code is required."
    end
  end

  def finish
    @ride.finish!
    redirect_to root_path, notice: "Ride was successfully finished."
  end

  # GET /rides/1 or /rides/1.json
  def show
  end

  # GET /rides/new
  def new
    if current_user.driver_profile.nil?
      redirect_to new_driver_profile_path, notice: "Please create a driver profile first."
    else
      @ride = Ride.new
    end
  end

  # GET /rides/1/edit
  def edit
  end

  # POST /rides or /rides.json
  def create
    # Initialize a new ride
    @ride = Ride.new

    # Set booking from params
    if params[:booking_id].present?
      @booking = Booking.find(params[:booking_id])

      # We don't need to set location data directly on the ride
      # since we'll associate the booking with the ride

      # Set driver to current user's driver profile
      @ride.driver = current_user.driver_profile if current_user.driver_profile

      # Set vehicle from params
      if params[:vehicle_id].present?
        @vehicle = Vehicle.find(params[:vehicle_id])
        @ride.vehicle = @vehicle
      end

      # Set initial status
      @ride.status = "accepted"

      # Apply any additional ride params if they exist
      @ride.assign_attributes(ride_params) if params[:ride].present?

      respond_to do |format|
        if @ride.save
          # Update booking status and associate with the ride
          if @booking
            @booking.update(status: "accepted", ride_id: @ride.id)
          end

          format.html { redirect_to @ride, notice: "Ride was successfully created." }
          format.json { render :show, status: :created, location: @ride }
          format.turbo_stream { redirect_to dashboard_path, notice: "Ride was successfully created." }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @ride.errors, status: :unprocessable_entity }
          format.turbo_stream { render turbo_stream: turbo_stream.replace("new_ride", partial: "rides/form", locals: { ride: @ride }) }
        end
      end
    else
      redirect_to dashboard_path, alert: "Booking ID is required to create a ride."
    end
  end

  # PATCH/PUT /rides/1 or /rides/1.json
  def update
    respond_to do |format|
      if @ride.update(ride_params)
        format.html { redirect_to dashboard_path, notice: "Ride was successfully updated." }
        format.json { render :show, status: :ok, location: @ride }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ride.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /rides/1 or /rides/1.json
  def destroy
    @ride.destroy!

    respond_to do |format|
      format.html { redirect_to rides_path, status: :see_other, notice: "Ride was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def mark_as_paid
    @ride = Ride.find(params[:id])

    if @ride.mark_paid!
      respond_to do |format|
        format.turbo_stream
      end
    else
      redirect_to rides_path, alert: "Could not mark ride as paid"
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ride
      @ride = Ride.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ride_params
      if params[:ride].present?
        params.require(:ride).permit(:status, :pickup_time, :dropoff_time, :driver_id, :vehicle_id)
      else
        {}
      end
    end

    def check_driver_requirements
      unless current_user.driver_profile&.vehicles&.any?
        redirect_to new_driver_profile_vehicle_path(current_user.driver_profile),
          notice: "Please add at least one vehicle before creating rides."
      end
    end
end
