require "net/http"

class GooglePlacesService
  GOOGLE_PLACES_API_URL = "https://maps.googleapis.com/maps/api/place/autocomplete/json"
  GOOGLE_PLACE_DETAILS_API_URL = "https://maps.googleapis.com/maps/api/place/details/json"

  def initialize(api_key)
    @api_key = api_key
  end

  def autocomplete(query)
    uri = URI(GOOGLE_PLACES_API_URL)
    params = {
      input: query,
      types: "geocode",
      key: @api_key
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    data = JSON.parse(response.body)

    locations = data["predictions"].map do |prediction|
      place_details = get_place_details(prediction["place_id"])
      {
        address: prediction["description"],
        latitude: place_details["lat"],
        longitude: place_details["lng"]
      }
    end

    locations
  end

  private

  def get_place_details(place_id)
    uri = URI(GOOGLE_PLACE_DETAILS_API_URL)
    params = {
      place_id: place_id,
      fields: "geometry",
      key: @api_key
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    data = JSON.parse(response.body)

    if data["status"] == "OK"
      data.dig("result", "geometry", "location") || {}
    else
      {}
    end
  end
end
