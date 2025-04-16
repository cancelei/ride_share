class AddRideIdToRatings < ActiveRecord::Migration[8.0]
  def change
    add_reference :ratings, :ride, foreign_key: true
  end
end
