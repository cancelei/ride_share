class CreateCompanyDrivers < ActiveRecord::Migration[8.0]
  def change
    create_table :company_drivers do |t|
      t.references :company_profile, null: false, foreign_key: true
      t.references :driver_profile, null: false, foreign_key: true

      t.timestamps
    end
  end
end
