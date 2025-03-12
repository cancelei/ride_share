class UpdateRidesForPendingState < ActiveRecord::Migration[8.0]
  def change
    # Add status column if it doesn't exist
    add_column :rides, :status, :integer, default: 0, null: false unless column_exists?(:rides, :status)

    # Make driver_id and vehicle_id optional by removing NOT NULL constraints if they exist
    change_column_null :rides, :driver_id, true
    change_column_null :rides, :vehicle_id, true
  end
end
