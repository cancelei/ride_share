class AddDiscardedAtToAllTables < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :discarded_at, :datetime
    add_index :users, :discarded_at

    add_column :driver_profiles, :discarded_at, :datetime
    add_index :driver_profiles, :discarded_at

    add_column :passenger_profiles, :discarded_at, :datetime
    add_index :passenger_profiles, :discarded_at

    # Vehicles and Locations
    add_column :vehicles, :discarded_at, :datetime
    add_index :vehicles, :discarded_at

    add_column :rides, :discarded_at, :datetime
    add_index :rides, :discarded_at
  end
end
