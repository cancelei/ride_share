class CompanyDriver < ApplicationRecord
  belongs_to :company_profile
  belongs_to :driver_profile

  # This method will be available after the migration adds the approved column
  # You can leave this out if you're relying on Rails' automatic boolean methods

  # Simple predicate method to check approval status
  def approved?
    approved == "true"
  end

  # Method to approve a driver
  def approve!
    update(approved: "true")
  end

  # Driver full name convenience method
  def driver_name
    user = driver_profile.user
    "#{user.first_name} #{user.last_name}"
  end

  # Scope for company's drivers
  scope :for_company, ->(company_profile) { where(company_profile: company_profile) }

  # Scope to include necessary associations
  scope :with_associations, -> { includes(driver_profile: :user) }

  after_update_commit -> { broadcast_replace_to company_profile }
  after_destroy_commit -> { broadcast_remove_to company_profile }

  after_update :sync_driver_company_id
  after_destroy :remove_driver_company_id

  private

  def sync_driver_company_id
    if approved == "true"
      driver_profile.update_column(:company_profile_id, company_profile_id)
    end
  end

  def remove_driver_company_id
    driver_profile.update_column(:company_profile_id, nil)
  end
end
