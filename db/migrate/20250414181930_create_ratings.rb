class CreateRatings < ActiveRecord::Migration[8.0]
  def change
    create_table :ratings do |t|
      t.float :score
      t.text :comment
      t.references :rateable, polymorphic: true, null: false
      t.references :rater, polymorphic: true, null: false

      t.timestamps
    end
  end
end
