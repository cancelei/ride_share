class CreateDriverProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :driver_profiles do |t|
      t.references :user, null: false, foreign_key: true, unique: true
      t.string :license, null: false
      t.string :license_issuer, null: false

      t.timestamps
    end
  end
end
