class RemoveRatingFromRides < ActiveRecord::Migration[8.0]
  def change
    remove_column :rides, :rating, :float
  end
end
