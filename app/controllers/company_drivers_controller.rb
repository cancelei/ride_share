class CompanyDriversController < ApplicationController
  include ActionView::RecordIdentifier
  include ActionView::Helpers::TagHelper

  before_action :authenticate_user!
  before_action :ensure_company_profile
  before_action :set_company_driver, only: [ :approve, :destroy ]

  def index
    @company_drivers = CompanyDriver.for_company(current_user.company_profile)
                                   .with_associations
  end

  def approve
    @company_driver.update(approved: "true")

    # Ensure the driver_profile's company_profile_id is updated
    @company_driver.driver_profile.update_column(:company_profile_id, @company_driver.company_profile_id)

    # Preload associations to avoid N+1 queries
    @company_driver = CompanyDriver.includes(
      driver_profile: [ :user, :vehicles ]
    ).find(@company_driver.id)

    respond_to do |format|
      format.html { redirect_to dashboard_path, notice: "Driver was successfully approved." }
      format.turbo_stream do
        # Create a new controller instance to get fresh stats
        dashboard_controller = DashboardController.new
        dashboard_controller.instance_variable_set(:@_request, request)
        dashboard_controller.instance_variable_set(:@_response, response)

        # Run set_stats to get all the updated stats
        dashboard_controller.send(:set_stats)

        # Extract all the necessary instance variables
        @active_rides = dashboard_controller.instance_variable_get(:@active_rides)
        @completed_rides = dashboard_controller.instance_variable_get(:@completed_rides)
        @cancelled_rides = dashboard_controller.instance_variable_get(:@cancelled_rides)
        @last_week_rides_total = dashboard_controller.instance_variable_get(:@last_week_rides_total)
        @monthly_rides_total = dashboard_controller.instance_variable_get(:@monthly_rides_total)
        @company_drivers = dashboard_controller.instance_variable_get(:@company_drivers)

        render turbo_stream: [
          turbo_stream.replace(dom_id(@company_driver), partial: "company_drivers/company_driver", locals: { company_driver: @company_driver }),
          turbo_stream.replace("financial_summary_card", partial: "dashboard/financial_summary", locals: {
            last_week_rides_total: @last_week_rides_total,
            monthly_rides_total: @monthly_rides_total
          }),
          turbo_stream.replace("ride_statistics_card", partial: "dashboard/ride_statistics", locals: {
            active_rides: @active_rides,
            completed_rides: @completed_rides,
            cancelled_rides: @cancelled_rides
          }),
          turbo_stream.replace("drivers_card", partial: "dashboard/drivers_card", locals: {
            company_drivers: @company_drivers,
            active_rides: @active_rides
          }),
          turbo_stream.replace("performance_card", partial: "dashboard/performance_card", locals: {
            completed_rides: @completed_rides,
            cancelled_rides: @cancelled_rides,
            active_rides: @active_rides
          }),
          turbo_stream.update("flash", partial: "shared/flash_notice", locals: { message: "Driver was successfully approved." })
        ]
      end
    end
  end

  def destroy
    driver_name = "#{@company_driver.driver_profile.user.first_name} #{@company_driver.driver_profile.user.last_name}"
    was_approved = @company_driver.approved == "true"
    company_driver_dom_id = dom_id(@company_driver)
    @company_driver.destroy

    respond_to do |format|
      format.html { redirect_to dashboard_path, notice: "#{driver_name} was removed from your company." }
      format.turbo_stream do
        streams = [ turbo_stream.remove(company_driver_dom_id) ]

        if was_approved
          # Create a new controller instance to get fresh stats
          dashboard_controller = DashboardController.new
          dashboard_controller.instance_variable_set(:@_request, request)
          dashboard_controller.instance_variable_set(:@_response, response)

          # Run set_stats to get all the updated stats
          dashboard_controller.send(:set_stats)

          # Extract all the necessary instance variables
          @active_rides = dashboard_controller.instance_variable_get(:@active_rides)
          @completed_rides = dashboard_controller.instance_variable_get(:@completed_rides)
          @cancelled_rides = dashboard_controller.instance_variable_get(:@cancelled_rides)
          @last_week_rides_total = dashboard_controller.instance_variable_get(:@last_week_rides_total)
          @monthly_rides_total = dashboard_controller.instance_variable_get(:@monthly_rides_total)
          @company_drivers = dashboard_controller.instance_variable_get(:@company_drivers)

          streams.concat([
            turbo_stream.replace("financial_summary_card", partial: "dashboard/financial_summary", locals: {
              last_week_rides_total: @last_week_rides_total,
              monthly_rides_total: @monthly_rides_total
            }),
            turbo_stream.replace("ride_statistics_card", partial: "dashboard/ride_statistics", locals: {
              active_rides: @active_rides,
              completed_rides: @completed_rides,
              cancelled_rides: @cancelled_rides
            }),
            turbo_stream.replace("drivers_card", partial: "dashboard/drivers_card", locals: {
              company_drivers: @company_drivers,
              active_rides: @active_rides
            }),
            turbo_stream.replace("performance_card", partial: "dashboard/performance_card", locals: {
              completed_rides: @completed_rides,
              cancelled_rides: @cancelled_rides,
              active_rides: @active_rides
            })
          ])
        end

        streams << turbo_stream.update("flash", partial: "shared/flash_notice", locals: { message: "#{driver_name} was removed from your company." })

        render turbo_stream: streams
      end
    end
  end

  def add_self_as_driver
    # Check if the user has a driver profile
    unless current_user.driver_profile
      redirect_to new_driver_profile_path, alert: "You need to create a driver profile first."
      return
    end

    # Check if they're already a driver in their company
    if CompanyDriver.exists?(company_profile_id: current_user.company_profile.id,
                            driver_profile_id: current_user.driver_profile.id)
      redirect_to dashboard_path, alert: "You are already a driver in your company."
      return
    end

    # Create the company driver record and approve it automatically
    @company_driver = CompanyDriver.new(
      company_profile_id: current_user.company_profile.id,
      driver_profile_id: current_user.driver_profile.id,
      approved: "true" # Auto-approve for company owner
    )

    if @company_driver.save
      # Update the driver profile's company association
      current_user.driver_profile.update_column(:company_profile_id, current_user.company_profile.id)

      respond_to do |format|
        format.html { redirect_to dashboard_path, notice: "You have been added as a driver to your company." }
        format.turbo_stream do
          # Create a new controller instance to get fresh stats
          dashboard_controller = DashboardController.new
          dashboard_controller.instance_variable_set(:@_request, request)
          dashboard_controller.instance_variable_set(:@_response, response)

          # Run set_stats to get all the updated stats
          dashboard_controller.send(:set_stats)

          # Extract all the necessary instance variables
          @active_rides = dashboard_controller.instance_variable_get(:@active_rides)
          @completed_rides = dashboard_controller.instance_variable_get(:@completed_rides)
          @cancelled_rides = dashboard_controller.instance_variable_get(:@cancelled_rides)
          @last_week_rides_total = dashboard_controller.instance_variable_get(:@last_week_rides_total)
          @monthly_rides_total = dashboard_controller.instance_variable_get(:@monthly_rides_total)
          @company_drivers = dashboard_controller.instance_variable_get(:@company_drivers)

          render turbo_stream: [
            turbo_stream.append("company_drivers tbody", partial: "company_drivers/company_driver", locals: { company_driver: @company_driver }),
            turbo_stream.replace("financial_summary_card", partial: "dashboard/financial_summary", locals: {
              last_week_rides_total: @last_week_rides_total,
              monthly_rides_total: @monthly_rides_total
            }),
            turbo_stream.replace("ride_statistics_card", partial: "dashboard/ride_statistics", locals: {
              active_rides: @active_rides,
              completed_rides: @completed_rides,
              cancelled_rides: @cancelled_rides
            }),
            turbo_stream.replace("drivers_card", partial: "dashboard/drivers_card", locals: {
              company_drivers: @company_drivers,
              active_rides: @active_rides
            }),
            turbo_stream.replace("performance_card", partial: "dashboard/performance_card", locals: {
              completed_rides: @completed_rides,
              cancelled_rides: @cancelled_rides,
              active_rides: @active_rides
            }),
            turbo_stream.replace("add_self_button_container", ""),
            turbo_stream.update("flash", partial: "shared/flash_notice", locals: { message: "You have been added as a driver to your company." })
          ]
        end
      end
    else
      redirect_to dashboard_path, alert: "There was a problem adding you as a driver."
    end
  end

  private

  def set_company_driver
    @company_driver = CompanyDriver.includes(driver_profile: [ :user, :vehicles ]).find(params[:id])
    unless @company_driver.company_profile == current_user.company_profile
      redirect_to dashboard_path, alert: "You can only manage drivers in your own company."
    end
  end

  def ensure_company_profile
    unless current_user.company_profile.present?
      redirect_to dashboard_path, alert: "You need a company profile to perform this action."
    end
  end
end
