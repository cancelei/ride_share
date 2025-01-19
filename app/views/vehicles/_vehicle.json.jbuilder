json.extract! vehicle, :id, :driver_profile_id, :registration_number, :seating_capacity, :brand, :model, :color, :fuel_avg, :built_year, :has_private_insurance, :created_at, :updated_at
json.url vehicle_url(vehicle, format: :json)
