json.extract! booking, :id, :passenger_id, :pickup, :dropoff, :scheduled_time, :status, :requested_seats, :special_instructions, :created_at, :updated_at
json.url booking_url(booking, format: :json)
