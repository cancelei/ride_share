module AddressFormatter
  extend ActiveSupport::Concern

  def format_address(full_address)
    return nil if full_address.blank?

    # Split address components
    components = full_address.split(", ")

    # Remove plus codes (they typically start with numbers and letters followed by a plus)
    components.reject! { |comp| comp.match?(/^[0-9A-Z]+\+/) }

    # Get meaningful address components
    street = components[0]
    district = components[1]
    city = components[2]
    country = components.last

    # Build formatted address
    [ street, district, city, country ].compact.join(", ")
  end
end
