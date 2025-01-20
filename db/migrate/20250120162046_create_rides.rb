class CreateRides < ActiveRecord::Migration[8.0]
  def change
    create_table :rides do |t|
      t.references :driver, foreign_key: { to_table: :driver_profiles }
      # Ride details
      t.string :pickup, null: false
      t.string :dropoff, null: false
      t.string :ride_type, null: false, limit: 50
      t.string :invitation_code, limit: 20
      t.datetime :scheduled_time
      t.integer :available_seats, null: false, default: 0
      t.string :status, null: false, limit: 20

      # Optional feedback fields
      t.integer :rating, limit: 1
      t.text :review

      # Pricing and cost details
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0.0
      t.decimal :discount, precision: 10, scale: 2, default: 0.0

      # Metrics
      t.string :distance, limit: 20
      t.string :estimated_time, limit: 20
      t.string :time_taken, limit: 20

      # Timestamps
      t.timestamps
    end

    # Add indexes for frequently queried columns
    add_index :rides, :ride_type
    add_index :rides, :status
    add_index :rides, :scheduled_time
  end
end
