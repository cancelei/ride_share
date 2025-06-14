class AddCompanyProfileIdToRides < ActiveRecord::Migration[8.0]
  def change
    add_reference :rides, :company_profile, null: true, index: true, foreign_key: { to_table: :company_profiles }
  end
end
