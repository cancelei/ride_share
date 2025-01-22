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

      t.timestamps
    end
  end
end
