class DriverProfilesController < ApplicationController
  before_action :set_driver_profile, only: %i[ show edit update destroy ]
  before_action :check_existing_profile, only: %i[ new create ]

  # GET /driver_profiles or /driver_profiles.json
  def index
    @driver_profiles = DriverProfile.where(user: current_user)
  end

  # GET /driver_profiles/1 or /driver_profiles/1.json
  def show
  end

  # GET /driver_profiles/new
  def new
    @driver_profile = DriverProfile.new
  end

  # GET /driver_profiles/1/edit
  def edit
  end

  # POST /driver_profiles or /driver_profiles.json
  def create
    @driver_profile = DriverProfile.new(driver_profile_params)

    respond_to do |format|
      if @driver_profile.save
        format.html { redirect_to @driver_profile, notice: "Driver profile was successfully created." }
        format.json { render :show, status: :created, location: @driver_profile }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @driver_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /driver_profiles/1 or /driver_profiles/1.json
  def update
    respond_to do |format|
      if @driver_profile.update(driver_profile_params)
        format.html { redirect_to @driver_profile, notice: "Driver profile was successfully updated." }
        format.json { render :show, status: :ok, location: @driver_profile }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @driver_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /driver_profiles/1 or /driver_profiles/1.json
  def destroy
    @driver_profile.destroy!

    respond_to do |format|
      format.html { redirect_to driver_profiles_path, status: :see_other, notice: "Driver profile was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def update_location
    latitude = params[:latitude]
    longitude = params[:longitude]

    current_user.broadcast_location(latitude, longitude)

    head :ok
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_driver_profile
      @driver_profile = DriverProfile.find(params.expect(:id))
    end

    def check_existing_profile
      redirect_back(fallback_location: root_path, notice: "You already have a driver profile.") if current_user.driver_profile.present?
    end

    # Only allow a list of trusted parameters through.
    def driver_profile_params
      params.expect(driver_profile: [ :user_id, :license, :license_issuer ])
    end
end
