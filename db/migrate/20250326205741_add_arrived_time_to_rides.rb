class AddArrivedTimeToRides < ActiveRecord::Migration[8.0]
  def change
    add_column :rides, :arrived_time, :datetime
  end
end
