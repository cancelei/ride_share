module PriceCalculator
  extend ActiveSupport::Concern

  def calculate_estimated_price
    base_fare = 5
    per_km_rate = 1.7

    (base_fare + (distance_km.to_f * per_km_rate)).round(2)
  end

  def formatted_price(price = nil)
    price ||= calculate_estimated_price
    ActionController::Base.helpers.number_to_currency(price, precision: 2, unit: "USD ")
  end
end
