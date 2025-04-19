module Reports
  class ManagerialReport
    def initialize(user, start_date, end_date)
      @user = user
      @start_date = start_date
      @end_date = end_date
    end

    def data
      if @user.role == "company" && @user.company_profile
        drivers = @user.company_profile.driver_profiles.includes(:user, :vehicles)
        driver_stats = drivers.map do |driver|
          driver_rides = Ride.where(driver_id: driver.id, scheduled_time: @start_date..@end_date)
          vehicles = driver.vehicles
          vehicle_stats = vehicles.map do |vehicle|
            rides = Ride.where(vehicle_id: vehicle.id, scheduled_time: @start_date..@end_date)
            {
              vehicle: vehicle,
              ride_count: rides.count,
              total_earnings: rides.sum(:estimated_price),
              completed_rides: rides.where(status: :completed).count,
              cancelled_rides: rides.where(status: :cancelled).count,
              avg_earning_per_ride: rides.count > 0 ? (rides.sum(:estimated_price).to_f / rides.count).round(2) : 0.0,
              top_ride_value: rides.maximum(:estimated_price) || 0.0,
              first_ride_at: rides.minimum(:scheduled_time),
              last_ride_at: rides.maximum(:scheduled_time)
            }
          end
          {
            driver: driver,
            driver_name: driver.user.full_name,
            ride_count: driver_rides.count,
            total_earnings: driver_rides.sum(:estimated_price),
            completed_rides: driver_rides.where(status: :completed).count,
            cancelled_rides: driver_rides.where(status: :cancelled).count,
            avg_earning_per_ride: driver_rides.count > 0 ? (driver_rides.sum(:estimated_price).to_f / driver_rides.count).round(2) : 0.0,
            vehicles: vehicle_stats
          }
        end

        # Company-wide stats
        all_rides = Ride.where(driver_id: drivers.map(&:id), scheduled_time: @start_date..@end_date)
        all_vehicles = drivers.flat_map(&:vehicles).uniq
        top_vehicle = all_vehicles.max_by { |v| Ride.where(vehicle_id: v.id, scheduled_time: @start_date..@end_date).sum(:estimated_price) }
        top_driver = drivers.max_by { |d| Ride.where(driver_id: d.id, scheduled_time: @start_date..@end_date).sum(:estimated_price) }
        {
          drivers: driver_stats,
          total_drivers: drivers.count,
          total_vehicles: all_vehicles.count,
          total_rides: all_rides.count,
          completed_rides: all_rides.where(status: :completed).count,
          cancelled_rides: all_rides.where(status: :cancelled).count,
          total_earnings: all_rides.sum(:estimated_price),
          avg_earning_per_ride: all_rides.count > 0 ? (all_rides.sum(:estimated_price).to_f / all_rides.count).round(2) : 0.0,
          top_vehicle: top_vehicle,
          top_vehicle_earnings: top_vehicle ? Ride.where(vehicle_id: top_vehicle.id, scheduled_time: @start_date..@end_date).sum(:estimated_price) : 0.0,
          top_driver: top_driver,
          top_driver_earnings: top_driver ? Ride.where(driver_id: top_driver.id, scheduled_time: @start_date..@end_date).sum(:estimated_price) : 0.0,
          earnings_over_time: all_rides.group_by_day(:scheduled_time, range: @start_date..@end_date).sum(:estimated_price)
        }
      elsif @user.role == "driver" && @user.driver_profile
        driver_rides = Ride.where(driver_id: @user.driver_profile.id, scheduled_time: @start_date..@end_date)
        # Group rides by company_profile_id at ride time
        rides_by_company = driver_rides.group_by { |ride| ride.driver.company_profile_id }
        company_stats = rides_by_company.map do |company_id, rides|
          company = CompanyProfile.find_by(id: company_id)
          {
            company: company,
            company_name: company&.name || "(No Company)",
            ride_count: rides.count,
            completed_rides: rides.count { |r| r.status == "completed" },
            cancelled_rides: rides.count { |r| r.status == "cancelled" },
            total_earnings: rides.sum { |r| r.estimated_price.to_f },
            avg_earning_per_ride: rides.count > 0 ? (rides.sum { |r| r.estimated_price.to_f } / rides.count).round(2) : 0.0
          }
        end
        vehicles = @user.driver_profile.vehicles
        vehicle_stats = vehicles.map do |vehicle|
          rides = Ride.where(vehicle_id: vehicle.id, scheduled_time: @start_date..@end_date)
          {
            vehicle: vehicle,
            ride_count: rides.count,
            total_earnings: rides.sum(:estimated_price),
            completed_rides: rides.where(status: :completed).count,
            cancelled_rides: rides.where(status: :cancelled).count,
            avg_earning_per_ride: rides.count > 0 ? (rides.sum(:estimated_price).to_f / rides.count).round(2) : 0.0,
            top_ride_value: rides.maximum(:estimated_price) || 0.0,
            first_ride_at: rides.minimum(:scheduled_time),
            last_ride_at: rides.maximum(:scheduled_time)
          }
        end
        {
          companies: company_stats,
          vehicles: vehicle_stats,
          total_vehicles: vehicles.count,
          total_rides: driver_rides.count,
          completed_rides: driver_rides.where(status: :completed).count,
          cancelled_rides: driver_rides.where(status: :cancelled).count,
          total_earnings: driver_rides.sum(:estimated_price),
          avg_earning_per_ride: driver_rides.count > 0 ? (driver_rides.sum(:estimated_price).to_f / driver_rides.count).round(2) : 0.0,
          top_vehicle: vehicles.max_by { |v| Ride.where(vehicle_id: v.id, scheduled_time: @start_date..@end_date).sum(:estimated_price) }
        }
      else
        {}
      end
    end
  end
end
