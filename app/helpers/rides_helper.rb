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
end
