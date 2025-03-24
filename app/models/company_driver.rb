class CompanyDriver < ApplicationRecord
  belongs_to :company_profile
  belongs_to :driver_profile
end
