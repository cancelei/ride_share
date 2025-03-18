class UsersController < ApplicationController
  before_action :require_admin!, except: [ :toggle_role ]
  before_action :set_user, only: [ :edit, :update, :destroy, :restore, :permanent_delete ]
  before_action :authenticate_user!, only: [ :toggle_role ]

  def index
    @users = if params[:show_deleted]
               User.with_discarded.order(created_at: :desc)
    else
               User.kept.order(created_at: :desc)
    end
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to users_path, notice: "User was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to users_path, notice: "User was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.discard
    redirect_to users_path, notice: "User was successfully deactivated."
  end

  def permanent_delete
    ActiveRecord::Base.transaction do
      if @user.driver_profile.present?
        # Handle rides
        @user.driver_profile.rides.destroy_all

        # Clear the selected_vehicle reference before deleting vehicles
        @user.driver_profile.update!(selected_vehicle: nil)

        # Then handle vehicles
        @user.driver_profile.vehicles.destroy_all

        # Finally destroy the driver profile
        @user.driver_profile.destroy!
      end

      if @user.passenger_profile.present?
        # Handle passenger's rides
        @user.passenger_profile.rides.destroy_all

        # Destroy the passenger profile
        @user.passenger_profile.destroy!
      end

      # Finally destroy the user
      @user.destroy!
    end

    redirect_to users_path, notice: "User was permanently deleted."
  rescue ActiveRecord::RecordNotDestroyed => e
    redirect_to users_path, alert: "Could not delete user: #{e.message}"
  end

  def restore
    @user.undiscard
    redirect_to users_path, notice: "User was successfully restored."
  end

  def toggle_role
    # Only toggle between passenger and driver roles
    current_role = current_user.role

    new_role = case current_role
    when "passenger"
                 "driver"
    when "driver"
                 "passenger"
    else
                 current_role # Keep the same role if not passenger or driver
    end

    if current_user.update(role: new_role)
      respond_to do |format|
        format.html { redirect_to dashboard_path, notice: "Your role has been updated to #{new_role}." }
        format.turbo_stream {
          flash.now[:notice] = "Your role has been updated to #{new_role}."
          redirect_to dashboard_path
        }
      end
    else
      respond_to do |format|
        format.html { redirect_to dashboard_path, alert: "There was a problem changing your role." }
        format.turbo_stream {
          flash.now[:alert] = "There was a problem changing your role."
          redirect_to dashboard_path
        }
      end
    end
  end

  private
  def require_admin!
    unless current_user.role_admin?
      redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end

  def set_user
    @user = User.with_discarded.find(params[:id])
  end

  # Only admins can update roles
  def user_params
    permitted_attributes = [ :email, :password, :password_confirmation, :first_name, :last_name, :country, :phone_number ]
    permitted_attributes << :role if current_user&.role_admin?
    params.require(:user).permit(permitted_attributes)
  end
end
