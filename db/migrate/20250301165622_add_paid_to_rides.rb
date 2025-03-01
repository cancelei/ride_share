class AddPaidToRides < ActiveRecord::Migration[8.0]
  def change
    add_column :rides, :paid, :boolean, default: false
    add_column :rides, :paid_at, :datetime
  end
end
