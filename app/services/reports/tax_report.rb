module Reports
  class TaxReport
    def initialize(user, start_date, end_date)
      @user = user
      @start_date = start_date
      @end_date = end_date
    end

    def data
      # Collect rides and payments for the user (driver or company) in the date range
      if @user.role == "company" && @user.company_profile
        rides = Ride.where(driver_id: @user.company_profile.driver_profiles.ids)
                     .where(scheduled_time: @start_date..@end_date)
      elsif @user.role == "driver" && @user.driver_profile
        rides = Ride.where(driver_id: @user.driver_profile.id)
                     .where(scheduled_time: @start_date..@end_date)
      else
        rides = Ride.none
      end
      {
        rides: rides,
        total_earnings: rides.sum(:estimated_price),
        # Time series of earnings for Chartkick
        earnings_over_time: rides.group_by_day(:scheduled_time, range: @start_date..@end_date).sum(:estimated_price)
      }
    end
  end
end
