class CreateRides < ActiveRecord::Migration[8.0]
  def change
    create_table :rides do |t|
      t.datetime :start_time
      t.datetime :end_time
      t.string :status
      t.float :rating
      t.integer :available_seats, default: 0
      t.float :estimated_price, precision: 10, scale: 2
      t.float :effective_price, precision: 10, scale: 2
      t.datetime :scheduled_time
      t.string :security_code
      t.boolean :paid, default: false
      t.datetime :paid_at
      t.string :pickup_address
      t.string :dropoff_address
      t.string :pickup_location
      t.string :dropoff_location
      t.float :pickup_lat
      t.float :pickup_lng
      t.float :dropoff_lat
      t.float :dropoff_lng
      t.decimal :distance_km, precision: 10, scale: 2
      t.integer :estimated_duration_minutes
      t.integer :total_travel_duration_minutes
      t.integer :requested_seats
      t.text :special_instructions
      t.references :driver, null: true, foreign_key: { to_table: :driver_profiles }
      t.references :passenger, null: true, foreign_key: { to_table: :passenger_profiles }
      t.references :vehicle, null: true, foreign_key: true
      t.timestamps
    end
  end
end
