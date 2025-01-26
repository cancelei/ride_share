module BookingsHelper
  def booking_status_color(status)
    case status.to_s
    when "pending"
      "text-yellow-600"
    when "accepted"
      "text-blue-600"
    when "in_progress"
      "text-green-600"
    when "completed"
      "text-gray-600"
    when "cancelled"
      "text-red-600"
    else
      "text-gray-600"
    end
  end
end
