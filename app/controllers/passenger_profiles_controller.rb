class PassengerProfilesController < ApplicationController
  before_action :set_passenger_profile, only: %i[ show edit update destroy ]

  # GET /passenger_profiles or /passenger_profiles.json
  def index
    @passenger_profiles = PassengerProfile.all
  end

  # GET /passenger_profiles/1 or /passenger_profiles/1.json
  def show
  end

  def shared_bookings
    @shared_bookings = Booking.where(passenger: @passenger_profile)
  end

  # GET /passenger_profiles/new
  def new
    @passenger_profile = PassengerProfile.new
  end

  # GET /passenger_profiles/1/edit
  def edit
  end

  # POST /passenger_profiles or /passenger_profiles.json
  def create
    @passenger_profile = PassengerProfile.new(passenger_profile_params)

    respond_to do |format|
      if @passenger_profile.save
        format.html { redirect_to root_path, notice: "Passenger profile was successfully created." }
        format.json { render :show, status: :created, location: @passenger_profile }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @passenger_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /passenger_profiles/1 or /passenger_profiles/1.json
  def update
    respond_to do |format|
      if @passenger_profile.update(passenger_profile_params)
        format.html { redirect_to root_path, notice: "Passenger profile was successfully updated." }
        format.json { render :show, status: :ok, location: @passenger_profile }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @passenger_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /passenger_profiles/1 or /passenger_profiles/1.json
  def destroy
    @passenger_profile.destroy!

    respond_to do |format|
      format.html { redirect_to passenger_profiles_path, status: :see_other, notice: "Passenger profile was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_passenger_profile
      @passenger_profile = PassengerProfile.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def passenger_profile_params
      params.expect(passenger_profile: [ :user_id, :whatsapp_number, :telegram_username ])
    end
end
