class VehiclesController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :set_driver_profile
  before_action :set_vehicle, only: [ :show, :edit, :update, :destroy, :select ]

  # GET /vehicles or /vehicles.json
  def index
    @vehicles = @driver_profile.vehicles
  end

  # GET /vehicles/1 or /vehicles/1.json
  def show
    @driver_profile = @vehicle.driver_profile

    respond_to do |format|
      format.html
      format.turbo_stream do
        if params[:expanded] == "true"
          render turbo_stream: turbo_stream.update(
            "vehicle_details_#{@vehicle.id}",
            partial: "vehicles/vehicle_details",
            locals: { vehicle: @vehicle }
          )
        else
          render turbo_stream: turbo_stream.update("vehicle_details_#{@vehicle.id}", "")
        end
      end
    end
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
        @driver_profile.update!(selected_vehicle_id: @vehicle.id) if @driver_profile.selected_vehicle_id.blank?
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
    previous_vehicle = @driver_profile.selected_vehicle
    was_already_selected = previous_vehicle == @vehicle

    if was_already_selected
      # If clicking the same vehicle, deselect it
      @driver_profile.update!(selected_vehicle_id: nil)
    else
      # Select the new vehicle
      @driver_profile.update!(selected_vehicle_id: @vehicle.id)
    end

    respond_to do |format|
      format.html { redirect_to root_path, notice: was_already_selected ? "Vehicle was unselected." : "Vehicle was successfully set as current." }
      format.turbo_stream do
        streams = []

        # Update the clicked vehicle
        streams << turbo_stream.replace(
          dom_id(@vehicle),
          partial: "dashboard/vehicles_list",
          locals: {
            vehicles: [ @vehicle ],
            driver_profile: @driver_profile.reload
          }
        )

        # Update the previously selected vehicle if it exists and is different
        if previous_vehicle && previous_vehicle != @vehicle
          streams << turbo_stream.replace(
            dom_id(previous_vehicle),
            partial: "dashboard/vehicles_list",
            locals: {
              vehicles: [ previous_vehicle ],
              driver_profile: @driver_profile
            }
          )
        end

        render turbo_stream: streams
      end
    end
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
