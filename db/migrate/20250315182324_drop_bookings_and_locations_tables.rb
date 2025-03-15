class DropBookingsAndLocationsTables < ActiveRecord::Migration[8.0]
  def up
    # Drop tables if they exist
    drop_table :bookings if table_exists?(:bookings)
    drop_table :locations if table_exists?(:locations)
  end

  def down
    # This migration is not reversible
    raise ActiveRecord::IrreversibleMigration
  end
end
