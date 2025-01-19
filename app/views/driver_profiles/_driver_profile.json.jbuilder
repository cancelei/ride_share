json.extract! driver_profile, :id, :user_id, :license, :license_issuer, :created_at, :updated_at
json.url driver_profile_url(driver_profile, format: :json)
