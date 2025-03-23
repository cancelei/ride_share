class CompanyDriver < ApplicationRecord
  belongs_to :company
  belongs_to :driver_profile
end
