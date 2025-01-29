class VehiclesController < ApplicationController
  before_action :set_driver_profile
  before_action :set_vehicle, only: %i[ show edit update destroy select ]

  # GET /vehicles or /vehicles.json
  def index
    @vehicles = @driver_profile.vehicles
  end

  # GET /vehicles/1 or /vehicles/1.json
  def show
  end

  # GET /vehicles/new
  def new
    @vehicle = @driver_profile.vehicles.build
  end

  # GET /vehicles/1/edit
  def edit
  end

  # POST /vehicles or /vehicles.json
  def create
    @vehicle = @driver_profile.vehicles.build(vehicle_params)

    respond_to do |format|
      if @vehicle.save
        format.html { redirect_to root_path, notice: "Vehicle was successfully created." }
        format.json { render :show, status: :created, location: @vehicle }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @vehicle.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /vehicles/1 or /vehicles/1.json
  def update
    respond_to do |format|
      if @vehicle.update(vehicle_params)
        format.html { redirect_to root_path, notice: "Vehicle was successfully updated." }
        format.json { render :show, status: :ok, location: @vehicle }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @vehicle.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /vehicles/1 or /vehicles/1.json
  def destroy
    @vehicle.destroy!

    respond_to do |format|
      format.html { redirect_to root_path, notice: "Vehicle was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def select
    @driver_profile.update!(selected_vehicle_id: @vehicle.id)
    redirect_to root_path, notice: "Vehicle was successfully set as current."
  end

  private
    def set_driver_profile
      @driver_profile = DriverProfile.find(params[:driver_profile_id])
    end

    def set_vehicle
      @vehicle = @driver_profile.vehicles.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def vehicle_params
      params.require(:vehicle).permit(
        :driver_profile_id,
        :registration_number,
        :seating_capacity,
        :brand,
        :model,
        :color,
        :fuel_avg,
        :built_year,
        :has_private_insurance
      )
    end
end
