class CompanyProfile < ApplicationRecord
  include Discard::Model
  default_scope -> { kept }

  belongs_to :user, -> { with_discarded }
  has_many :company_drivers, dependent: :destroy
  has_many :driver_profiles, through: :company_drivers

  validates :name, presence: true

  # Returns the average rating across all drivers in the company
  def average_driver_rating
    scores = driver_profiles.joins(:ratings).pluck("ratings.score")
    return nil if scores.empty?
    (scores.sum.to_f / scores.size).round(2)
  end

  # Returns the total number of ratings across all drivers
  def total_driver_ratings
    driver_profiles.joins(:ratings).count
  end

  # Returns a hash breakdown of ratings (e.g., {5=>10, 4=>7, ...})
  def driver_rating_distribution
    driver_profiles.joins(:ratings).group("ratings.score").count
  end
end
