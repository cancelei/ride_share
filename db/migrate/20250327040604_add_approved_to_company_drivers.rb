class AddApprovedToCompanyDrivers < ActiveRecord::Migration[8.0]
  def change
    add_column :company_drivers, :approved, :string, default: false
  end
end
