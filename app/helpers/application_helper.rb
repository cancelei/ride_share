module ApplicationHelper
  def country_options
    ISO3166::Country.all.map do |country|
      [ "#{country.iso_short_name} #{country.emoji_flag}", country.iso_short_name ]
    end.sort_by { |c| c[1] }
  end
end
