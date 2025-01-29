class CreateDriverProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :driver_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :license, null: false
      t.string :license_issuer, null: false
      t.string :bitcoin_address
      t.string :icc_address
      t.string :ethereum_address

      t.timestamps
    end
  end
end
