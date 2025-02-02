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
    @ride.start!
    redirect_to root_path, notice: "Ride was successfully started."
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
    @ride = Ride.new(ride_params)

    respond_to do |format|
      if @ride.save
        format.html { redirect_to root_path, notice: "Ride was successfully created." }
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ride
      @ride = Ride.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def ride_params
      params.require(:ride).permit(
        :driver_id,
        :booking_id,
        :invitation_code,
        :status,
        :rating,
        :available_seats,
        :vehicle_id
      )
    end

    def check_driver_requirements
      unless current_user.driver_profile&.vehicles&.any?
        redirect_to new_driver_profile_vehicle_path(current_user.driver_profile),
          notice: "Please add at least one vehicle before creating rides."
      end
    end
end
