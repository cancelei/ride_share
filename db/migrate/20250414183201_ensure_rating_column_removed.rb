class EnsureRatingColumnRemoved < ActiveRecord::Migration[8.0]
  def up
    # Check if the column exists and remove it if it does
    if column_exists?(:rides, :rating)
      remove_column :rides, :rating
    end
  end

  def down
    # This is a safety migration, no need to add the column back
  end
end
