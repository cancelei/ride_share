json.extract! ride, :id, :driver_id, :invitation_code, :status, :rating, :available_seats, :created_at, :updated_at
json.url ride_url(ride, format: :json)
