class RidesController < ApplicationController
  before_action :set_ride, only: %i[ show edit update destroy ]
  before_action :authenticate_passenger, only: %i[ new create ]

  # GET /rides or /rides.json
  def index
    @rides = Ride.all
  end

  # GET /rides/1 or /rides/1.json
  def show
  end

  # GET /rides/new
  def new
    @ride = Ride.new
  end

  # GET /rides/1/edit
  def edit
  end

  # POST /rides or /rides.json
  def create
    @ride = Ride.new(ride_params)

    respond_to do |format|
      if @ride.save
        format.html { redirect_to @ride, notice: "Ride was successfully created." }
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
      if @ride.update(ride_params)
        format.html { redirect_to @ride, notice: "Ride was successfully updated." }
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

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_ride
    @ride = Ride.find(params.expect(:id))
  end

  def authenticate_passenger
    redirect_back(fallback_location: root_path, notice: "Only passengers can book rides") unless current_user.role_passenger?
  end

  # Only allow a list of trusted parameters through.
  def ride_params
    params.expect(ride: [ :driver_id, :passenger_id, :pickup, :dropoff, :ride_type, :invitation_code, :scheduled_time, :available_seats, :status, :rating, :review, :price, :discount, :distance, :estimated_time, :time_taken ])
  end
end
