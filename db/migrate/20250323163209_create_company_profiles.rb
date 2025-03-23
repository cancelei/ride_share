class CreateCompanyProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :company_profiles do |t|
      t.string :name
      t.string :description
      t.string :whatsapp_number
      t.string :telegram_number
      t.datetime :discarded_at
      t.index :discarded_at
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
