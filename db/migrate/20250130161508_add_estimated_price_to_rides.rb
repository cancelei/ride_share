class AddEstimatedPriceToRides < ActiveRecord::Migration[8.0]
  def change
    add_column :rides, :estimated_price, :float, precision: 10, scale: 2
    add_column :rides, :effective_price, :float, precision: 10, scale: 2
  end
end
