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

  def ride_status_class(status)
    case status.to_s
    when "pending"
      "bg-yellow-100 text-yellow-800"
    when "accepted"
      "bg-blue-100 text-blue-800"
    when "in_progress"
      "bg-indigo-100 text-indigo-800"
    when "completed"
      "bg-green-100 text-green-800"
    when "cancelled"
      "bg-red-100 text-red-800"
    else
      "bg-gray-100 text-gray-800"
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
