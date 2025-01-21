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

ActiveRecord::Schema[8.0].define(version: 2025_01_20_162046) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "driver_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "license", null: false
    t.string "license_issuer", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "selected_vehicle_id"
    t.index ["selected_vehicle_id"], name: "index_driver_profiles_on_selected_vehicle_id"
    t.index ["user_id"], name: "index_driver_profiles_on_user_id"
  end

  create_table "passenger_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "whatsapp_number"
    t.string "telegram_username"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_passenger_profiles_on_user_id"
  end

  create_table "rides", force: :cascade do |t|
    t.bigint "driver_id"
    t.bigint "passenger_id"
    t.string "pickup", null: false
    t.string "dropoff", null: false
    t.string "ride_type", limit: 50, null: false
    t.string "invitation_code", limit: 20
    t.datetime "scheduled_time"
    t.integer "available_seats", default: 0
    t.string "status", limit: 20, null: false
    t.integer "rating", limit: 2
    t.text "review"
    t.decimal "price", precision: 10, scale: 2, default: "0.0"
    t.decimal "discount", precision: 10, scale: 2, default: "0.0"
    t.string "distance", limit: 20
    t.string "estimated_time", limit: 20
    t.string "time_taken", limit: 20
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["driver_id"], name: "index_rides_on_driver_id"
    t.index ["passenger_id"], name: "index_rides_on_passenger_id"
    t.index ["ride_type"], name: "index_rides_on_ride_type"
    t.index ["scheduled_time"], name: "index_rides_on_scheduled_time"
    t.index ["status"], name: "index_rides_on_status"
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
    t.index ["driver_profile_id"], name: "index_vehicles_on_driver_profile_id"
  end

  add_foreign_key "driver_profiles", "users"
  add_foreign_key "driver_profiles", "vehicles", column: "selected_vehicle_id"
  add_foreign_key "passenger_profiles", "users"
  add_foreign_key "rides", "driver_profiles", column: "driver_id"
  add_foreign_key "rides", "passenger_profiles", column: "passenger_id"
  add_foreign_key "vehicles", "driver_profiles"
end
