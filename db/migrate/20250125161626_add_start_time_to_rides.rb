class AddStartTimeToRides < ActiveRecord::Migration[8.0]
  def change
    add_column :rides, :start_time, :datetime
  end
end
