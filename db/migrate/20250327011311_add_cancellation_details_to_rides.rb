class AddCancellationDetailsToRides < ActiveRecord::Migration[8.0]
  def change
    add_column :rides, :cancellation_reason, :string
    add_column :rides, :cancelled_by, :string
  end
end
