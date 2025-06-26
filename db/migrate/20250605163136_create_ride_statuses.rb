class CreateRideStatuses < ActiveRecord::Migration[8.0]
  def change
    create_table :ride_statuses do |t|
      t.string :status, null: false, default: "pending"
      t.references :ride, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
