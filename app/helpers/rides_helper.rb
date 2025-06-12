module RidesHelper
  def ride_status_color(status)
    case status.to_s
    when "pending"
      "yellow"
    when "accepted"
      "blue"
    when "waiting_for_passenger_boarding"
      "purple"
    when "in_progress"
      "indigo"
    when "rating_required"
      "amber"
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
    when "waiting_for_passenger_boarding"
      "bg-purple-100 text-purple-800"
    when "in_progress"
      "bg-indigo-100 text-indigo-800"
    when "rating_required"
      "bg-amber-100 text-amber-800"
    when "completed"
      "bg-green-100 text-green-800"
    when "cancelled"
      "bg-red-100 text-red-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def filter_rides_by_tab(rides, tab_type, user_id)
    case tab_type.to_s
    when "history"
      rides.includes(:driver, :passenger).historical_rides(user_id)
    else # 'active' or any other value
      rides.includes(:driver, :passenger).passenger_active(user_id)
    end
  end

  def ride_status(ride, user_id)
    ride.ride_statuses.find_by(user_id: user_id)&.status || ride.status
  end

  # Check if driver payment info should be displayed
  def show_driver_payment_info?(ride, current_user)
    (ride_status(ride, current_user.id) == "accepted" || ride_status(ride, current_user.id) == "waiting_for_passenger_boarding" || ride_status(ride, current_user.id) == "in_progress") &&
      current_user&.role_passenger? &&
      current_user&.passenger_profile == ride.passenger
  end

  # Get payment method icon based on type
  def payment_method_icon(payment_type)
    case payment_type.to_s
    when "bank_account"
      '<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 14v3m4-3v3m4-3v3M3 21h18M3 10h18M3 7l9-4 9 4M4 10h16v11H4V10z" /></svg>'
    when "card"
      '<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-indigo-600" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" /></svg>'
    when "pix"
      '<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>'
    when "paypal"
      '<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-blue-700" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" /></svg>'
    else
      '<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" /></svg>'
    end
  end
end
