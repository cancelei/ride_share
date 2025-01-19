class CreateVehicles < ActiveRecord::Migration[8.0]
  def change
    create_table :vehicles do |t|
      t.references :driver_profile, null: false, foreign_key: true
      t.string :registration_number, null: false
      t.integer :seating_capacity, null: false
      t.string :brand, null: false
      t.string :model, null: false
      t.string :color, null: false
      t.float :fuel_avg, null: true
      t.integer :built_year, null: true
      t.boolean :has_private_insurance, null: true

      t.timestamps
    end
  end
end
