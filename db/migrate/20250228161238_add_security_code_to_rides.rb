class AddSecurityCodeToRides < ActiveRecord::Migration[8.0]
  def change
    add_column :rides, :security_code, :string
  end
end
