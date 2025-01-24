class AddDistanceAndDurationToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings, :distance_km, :decimal
    add_column :bookings, :estimated_duration_minutes, :integer
    add_column :bookings, :remaing_durantion_minutes, :integer
    add_column :bookings, :total_travel_duration_minutes, :integer
  end
end
