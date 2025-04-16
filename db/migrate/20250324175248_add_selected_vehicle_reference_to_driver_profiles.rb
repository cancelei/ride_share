class AddSelectedVehicleReferenceToDriverProfiles < ActiveRecord::Migration[8.0]
  def up
    # First remove the existing foreign key
    remove_foreign_key :driver_profiles, column: :selected_vehicle_id
    # Add the new foreign key with nullify option
    add_foreign_key :driver_profiles, :vehicles, column: :selected_vehicle_id, on_delete: :nullify
  end

  def down
    # Revert back to original foreign key
    remove_foreign_key :driver_profiles, column: :selected_vehicle_id
    add_foreign_key :driver_profiles, :vehicles, column: :selected_vehicle_id
  end
end
