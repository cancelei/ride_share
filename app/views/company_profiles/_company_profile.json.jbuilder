json.extract! company_profile, :id, :name, :description, :whatsapp_number, :telegram_number, :created_at, :updated_at
json.url company_profile_url(company_profile, format: :json)
