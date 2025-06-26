class RemoveStatusFromRide < ActiveRecord::Migration[8.0]
  def change
    remove_column :rides, :status, :string, default: "pending", null: false
  end
end
