json.extract! ride, :id, :driver_id, :pickup, :dropoff, :ride_type, :invitation_code, :scheduled_time, :available_seats, :status, :rating, :review, :price, :discount, :distance, :estimated_time, :time_taken, :created_at, :updated_at
json.url ride_url(ride, format: :json)
