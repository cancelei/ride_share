# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_03_19_221259) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "driver_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "license", null: false
    t.string "license_issuer", null: false
    t.string "bitcoin_address"
    t.string "icc_address"
    t.string "ethereum_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "selected_vehicle_id"
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_driver_profiles_on_discarded_at"
    t.index ["selected_vehicle_id"], name: "index_driver_profiles_on_selected_vehicle_id"
    t.index ["user_id"], name: "index_driver_profiles_on_user_id"
  end

  create_table "passenger_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "whatsapp_number"
    t.string "telegram_username"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_passenger_profiles_on_discarded_at"
    t.index ["user_id"], name: "index_passenger_profiles_on_user_id"
  end

  create_table "rides", force: :cascade do |t|
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "invitation_code"
    t.string "status"
    t.float "rating"
    t.integer "available_seats"
    t.string "title"
    t.string "location"
    t.integer "participants_count", default: 0
    t.float "estimated_price"
    t.float "effective_price"
    t.datetime "scheduled_time"
    t.string "security_code"
    t.boolean "paid", default: false
    t.datetime "paid_at"
    t.string "pickup_address"
    t.string "dropoff_address"
    t.string "pickup_location"
    t.string "dropoff_location"
    t.float "pickup_lat"
    t.float "pickup_lng"
    t.float "dropoff_lat"
    t.float "dropoff_lng"
    t.decimal "distance_km", precision: 10, scale: 2
    t.integer "estimated_duration_minutes"
    t.integer "total_travel_duration_minutes"
    t.integer "requested_seats"
    t.text "special_instructions"
    t.bigint "driver_id"
    t.bigint "passenger_id"
    t.bigint "vehicle_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_rides_on_discarded_at"
    t.index ["driver_id"], name: "index_rides_on_driver_id"
    t.index ["passenger_id"], name: "index_rides_on_passenger_id"
    t.index ["vehicle_id"], name: "index_rides_on_vehicle_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 2, null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone_number"
    t.string "country"
    t.decimal "current_latitude", precision: 10, scale: 6
    t.decimal "current_longitude", precision: 10, scale: 6
    t.datetime "location_updated_at"
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vehicles", force: :cascade do |t|
    t.bigint "driver_profile_id", null: false
    t.string "registration_number", null: false
    t.integer "seating_capacity", null: false
    t.string "brand", null: false
    t.string "model", null: false
    t.string "color", null: false
    t.float "fuel_avg"
    t.integer "built_year"
    t.boolean "has_private_insurance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_vehicles_on_discarded_at"
    t.index ["driver_profile_id"], name: "index_vehicles_on_driver_profile_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "driver_profiles", "users"
  add_foreign_key "driver_profiles", "vehicles", column: "selected_vehicle_id"
  add_foreign_key "passenger_profiles", "users"
  add_foreign_key "rides", "driver_profiles", column: "driver_id"
  add_foreign_key "rides", "passenger_profiles", column: "passenger_id"
  add_foreign_key "rides", "vehicles"
  add_foreign_key "vehicles", "driver_profiles"
end
