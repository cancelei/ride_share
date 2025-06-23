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
    if @user.update(user_params.to_h.compact_blank)
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
    # Get the requested role from params
    new_role = params[:role]

    # Check if the role is valid using the User model's role enum
    if User.roles.keys.include?(new_role)
      # Store the previous role for potential handling
      previous_role = current_user.role

      # Update role with validation
      begin
        ActiveRecord::Base.transaction do
          current_user.update!(role: new_role)

          # If switching to company role and no company profile exists
          if new_role == "company" && !current_user.company_profile.present?
            flash[:notice] = "Please create a company profile to use all company features"
          end

          # If switching to driver role and no driver profile exists
          if new_role == "driver" && !current_user.driver_profile.present?
            # Create a basic driver profile to prevent initialization errors
            current_user.create_driver_profile! if current_user.driver_profile.nil?
            flash[:notice] = "Please complete your driver profile to start accepting rides"
          end
        end
      rescue => e
        Rails.logger.error("Role toggle failed: #{e.message}")
        flash[:alert] = "Could not change your role. Please try again."
      end
    end

    # Redirect back to dashboard
    redirect_to dashboard_path
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
