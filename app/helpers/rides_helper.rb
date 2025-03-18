module RidesHelper
  def ride_status_color(status)
    case status.to_s
    when "pending"
      "yellow"
    when "accepted"
      "blue"
    when "in_progress"
      "indigo"
    when "completed"
      "green"
    when "cancelled"
      "red"
    else
      "gray"
    end
  end

  def filter_rides_by_tab(rides, tab_type)
    case tab_type.to_s
    when "history"
      rides.where(status: [ :completed, :cancelled ])
    else # 'active' or any other value
      rides.where(status: [ :pending, :accepted, :in_progress ])
    end
  end
end
