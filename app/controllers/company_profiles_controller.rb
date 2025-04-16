class CompanyProfilesController < ApplicationController
  before_action :set_company_profile, only: %i[ show edit update destroy ]

  # GET /company_profiles or /company_profiles.json
  def index
    @company_profiles = CompanyProfile.all
  end

  # GET /company_profiles/1 or /company_profiles/1.json
  def show
  end

  # GET /company_profiles/new
  def new
    @company_profile = CompanyProfile.new
  end

  # GET /company_profiles/1/edit
  def edit
  end

  # POST /company_profiles or /company_profiles.json
  def create
    @company_profile = CompanyProfile.new(company_profile_params)

    if @company_profile.save
      redirect_to dashboard_path, notice: "Company profile was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /company_profiles/1 or /company_profiles/1.json
  def update
    respond_to do |format|
      if @company_profile.update(company_profile_params)
        format.html { redirect_to dashboard_path, notice: "Company profile was successfully updated." }
        format.json { render :show, status: :ok, location: @company_profile }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @company_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /company_profiles/1 or /company_profiles/1.json
  def destroy
    @company_profile.destroy!

    respond_to do |format|
      format.html { redirect_to company_profiles_path, status: :see_other, notice: "Company profile was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_company_profile
      @company_profile = CompanyProfile.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def company_profile_params
      params.expect(company_profile: [ :name, :description, :whatsapp_number, :telegram_number, :user_id ])
    end
end
