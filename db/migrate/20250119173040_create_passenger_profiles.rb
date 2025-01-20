class CreatePassengerProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :passenger_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :whatsapp_number
      t.string :telegram_username

      t.timestamps
    end
  end
end
