class AddCurrentLocationInfoToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :current_latitude, :decimal, precision: 10, scale: 6
    add_column :users, :current_longitude, :decimal, precision: 10, scale: 6
    add_column :users, :location_updated_at, :datetime
  end
end
