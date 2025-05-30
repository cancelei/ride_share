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
        format.html { redirect_to root_path, notice: "Driver profile was successfully created." }
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
      # Check if company was changed
      old_company_id = @driver_profile.company_profile_id
      new_company_id = driver_profile_params[:company_profile_id]

      if @driver_profile.update(driver_profile_params)
        # Handle company change
        if new_company_id.present? && old_company_id != new_company_id.to_i
          # Create a new company association
          CompanyDriver.where(driver_profile: @driver_profile).destroy_all
          CompanyDriver.create(
            driver_profile: @driver_profile,
            company_profile_id: new_company_id,
            approved: "false"
          )
          # Reset the company_profile_id until approved
          @driver_profile.update_column(:company_profile_id, nil)
          notice = "Driver profile was updated. Your request to join the company is pending approval."
        elsif new_company_id.blank? && old_company_id.present?
          # Driver wants to go solo
          CompanyDriver.where(driver_profile: @driver_profile).destroy_all
          notice = "Driver profile was updated. You are now a solo driver."
        else
          notice = "Driver profile was successfully updated."
        end

        format.html { redirect_to root_path, notice: notice }
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
    latitude = params[:latitude].to_f
    longitude = params[:longitude].to_f

    current_user.update_location(latitude, longitude)
    head :ok
  end

  def cancel_company_request
    company_driver = CompanyDriver.find_by(driver_profile: current_user.driver_profile)

    if company_driver
      company_name = company_driver.company_profile.name
      company_driver.destroy

      redirect_to dashboard_path, notice: "Your request to join #{company_name} has been canceled."
    else
      redirect_to dashboard_path, alert: "No pending company request found."
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_driver_profile
      @driver_profile = DriverProfile.find(params.require(:id))
    end

    def check_existing_profile
      redirect_back(fallback_location: root_path, notice: "You already have a driver profile.") if current_user.driver_profile.present?
    end

    # Only allow a list of trusted parameters through.
    def driver_profile_params
      params.require(:driver_profile).permit(:user_id, :license, :license_issuer, :company_profile_id, :bitcoin_address, :icc_address, :ethereum_address)
    end
end
