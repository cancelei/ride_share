class CreateBookings < ActiveRecord::Migration[8.0]
  def change
    create_table :bookings do |t|
      t.references :passenger, null: false, foreign_key: { to_table: :passenger_profiles }
      t.references :ride, foreign_key: true
      t.string :pickup
      t.string :dropoff
      t.datetime :scheduled_time
      t.string :status
      t.integer :requested_seats
      t.text :special_instructions

      t.decimal :distance_km, precision: 10, scale: 6
      t.integer :estimated_duration_minutes
      t.integer :remaing_durantion_minutes
      t.integer :total_travel_duration_minutes

      t.timestamps
    end
  end
end
