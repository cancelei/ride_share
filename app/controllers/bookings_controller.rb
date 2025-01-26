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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_booking
      @booking = Booking.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def booking_params
      params.require(:booking).permit(
        :passenger_id,
        :pickup,
        :dropoff,
        :scheduled_time,
        :status,
        :requested_seats,
        :special_instructions,
        :distance_km,
        :estimated_duration_minutes,
        :remaining_duration_minutes,
        :total_travel_duration_minutes,
        locations_attributes: [
          :address,
          :latitude,
          :longitude,
          :location_type
        ]
      )
    end
end
