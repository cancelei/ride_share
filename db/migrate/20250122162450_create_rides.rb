class CreateRides < ActiveRecord::Migration[8.0]
  def change
    create_table :rides do |t|
      t.references :driver, null: false, foreign_key: { to_table: :driver_profiles }
      t.datetime :start_time
      t.datetime :end_time
      t.string :invitation_code
      t.string :status
      t.float :rating
      t.integer :available_seats
      t.string :title
      t.string :location
      t.integer :participants_count, default: 0

      t.timestamps

      t.references :vehicle, null: false, foreign_key: true
    end
  end
end
