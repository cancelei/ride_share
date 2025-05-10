module UsersHelper
  def country_options
    ISO3166::Country.all.map do |country|
      [ country.iso_short_name, country.alpha2 ]
    end.sort_by { |name, _code| name }
  end
end
