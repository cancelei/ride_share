class BookingsController < ApplicationController
  before_action :set_booking, only: %i[ show edit update destroy cancel ]

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
    Time.zone = "America/Tegucigalpa"
    @booking = Booking.new(
      scheduled_time: Time.zone.now + 30.minutes
    )
  end

  # GET /bookings/1/edit
  def edit
  end

  # POST /bookings or /bookings.json
  def create
    @booking = Booking.new(booking_params)

    respond_to do |format|
      if @booking.save
        format.turbo_stream {
          flash.now[:notice] = "Booking was successfully created."
          render turbo_stream: [
            turbo_stream.update("flash", partial: "shared/flash"),
            turbo_stream.append_all("body",
              %{<turbo-frame id="redirect_handle">
                <script>Turbo.visit('/', { action: 'replace' })</script>
              </turbo-frame>}.html_safe
            )
          ]
        }
        format.html { redirect_to root_path, notice: "Booking was successfully created." }
      else
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "new_booking_form",
            partial: "form",
            locals: { booking: @booking }
          )
        }
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /bookings/1 or /bookings/1.json
  def update
    respond_to do |format|
      if @booking.update(booking_params)
        format.html { redirect_to root_path, notice: "Booking was successfully updated." }
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
      format.html { redirect_to root_path, status: :see_other, notice: "Booking was successfully destroyed." }
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

  def cancel
    if @booking.status_pending?
      @booking.update(status: :cancelled)
      redirect_to root_path, notice: "Booking was successfully cancelled."
    else
      redirect_to root_path, alert: "Only pending bookings can be cancelled."
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_booking
      @booking = Booking.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def booking_params
      params.require(:booking).permit(
        :passenger_id,
        :pickup,
        :dropoff,
        :scheduled_time,
        :requested_seats,
        :special_instructions,
        :distance_km,
        :estimated_duration_minutes,
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
