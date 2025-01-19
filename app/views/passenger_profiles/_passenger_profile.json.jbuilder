json.extract! passenger_profile, :id, :user_id, :whatsapp_number, :telegram_username, :created_at, :updated_at
json.url passenger_profile_url(passenger_profile, format: :json)
