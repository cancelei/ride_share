class BookingsController < ApplicationController
  before_action :set_booking, only: %i[ show edit update destroy ]

  # GET /bookings or /bookings.json
  def index
    @bookings = Booking.where(passenger: current_user.passenger_profile)
  end

  def shared_bookings
    @shared_bookings = Booking.where(passenger: current_user.passenger_profile)
  end

  # GET /bookings/1 or /bookings/1.json
  def show
  end

  # GET /bookings/new
  def new
    if current_user.passenger_profile.nil?
      redirect_to new_passenger_profile_path, notice: "Please create a passenger profile first."
    else
      @booking = Booking.new
    end
  end

  # GET /bookings/1/edit
  def edit
  end

  # POST /bookings or /bookings.json
  def create
    @booking = Booking.new(booking_params)

    # Create pickup location
    @booking.locations.build(
      address: params[:booking][:booking_pickup_location_attributes_address],
      latitude: params[:booking][:booking_pickup_location_attributes_latitude],
      longitude: params[:booking][:booking_pickup_location_attributes_longitude],
      location_type: "pickup"
    )

    # Create dropoff location
    @booking.locations.build(
      address: params[:booking][:booking_dropoff_location_attributes_address],
      latitude: params[:booking][:booking_dropoff_location_attributes_latitude],
      longitude: params[:booking][:booking_dropoff_location_attributes_longitude],
      location_type: "dropoff"
    )

    respond_to do |format|
      if @booking.save
        format.html { redirect_to @booking, notice: "Booking was successfully created." }
        format.json { render :show, status: :created, location: @booking }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @booking.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /bookings/1 or /bookings/1.json
  def update
    respond_to do |format|
      if @booking.update(booking_params)
        format.html { redirect_to @booking, notice: "Booking was successfully updated." }
        format.json { render :show, status: :ok, location: @booking }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @booking.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /bookings/1 or /bookings/1.json
  def destroy
    @booking.destroy!

    respond_to do |format|
      format.html { redirect_to bookings_path, status: :see_other, notice: "Booking was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def pending
    @bookings = Booking.where(status: :pending)
  end

  def driver_location
    @booking = Booking.find(params[:id])

    if @booking.ride&.driver&.user
      begin
        render json: {
          location: @booking.ride.driver.user.current_location,
          distance_to_pickup: @booking.calculate_distance_to_driver,
          eta_minutes: @booking.calculate_eta_minutes
        }
      rescue => e
        Rails.logger.error("Error calculating driver location: #{e.message}")
        render json: { error: "Unable to calculate distance" }, status: :unprocessable_entity
      end
    else
      render json: { error: "Driver not found" }, status: :not_found
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_booking
      @booking = Booking.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def booking_params
      params.require(:booking).permit(
        :passenger_id,
        :scheduled_time,
        :requested_seats,
        :special_instructions,
        :distance_km,
        :estimated_duration_minutes,
        :remaining_duration_minutes,
        :total_travel_duration_minutes
      )
    end
end
