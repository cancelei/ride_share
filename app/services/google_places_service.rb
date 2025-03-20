require "net/http"

class GooglePlacesService
  GOOGLE_PLACES_API_URL = "https://maps.googleapis.com/maps/api/place/autocomplete/json"
  GOOGLE_PLACE_DETAILS_API_URL = "https://maps.googleapis.com/maps/api/place/details/json"
  GOOGLE_DISTANCE_MATRIX_API_URL = "https://maps.googleapis.com/maps/api/distancematrix/json"

  def initialize
    @api_key = ENV["GOOGLE_MAPS_API_KEY"]
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
      {
        id: prediction["place_id"],
        address: prediction["description"]
      }
    end

    locations
  end

  def fetch_distance_matrix(pickup_lat, pickup_lng, dropoff_lat, dropoff_lng)
    origin = "#{pickup_lat},#{pickup_lng}"
    destination = "#{dropoff_lat},#{dropoff_lng}"
    uri = URI(GOOGLE_DISTANCE_MATRIX_API_URL)
    params = {
      origins: origin,
      destinations: destination,
      mode: "driving",
      key: @api_key
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
  end

  def details(place_id)
    uri = URI(GOOGLE_PLACE_DETAILS_API_URL)
    params = {
      place_id: place_id,
      fields: "geometry",
      key: @api_key
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    data = JSON.parse(response.body)

    details = {}

    details = data.dig("result", "geometry", "location") || {} if data["status"] == "OK"

    # get only lat and lng from details
    { latitude: details["lat"], longitude: details["lng"] } if details.present?
  end

  def reverse_geocode(lat, lng)
    # Google Geocoding API URL
    geocoding_api_url = "https://maps.googleapis.com/maps/api/geocode/json"

    uri = URI(geocoding_api_url)
    params = {
      latlng: "#{lat},#{lng}",
      key: @api_key
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    data = JSON.parse(response.body)

    if data["status"] == "OK" && data["results"].present?
      result = data["results"].first

      {
        id: result["place_id"],
        address: result["formatted_address"],
        latitude: lat,
        longitude: lng
      }
    else
      { error: "Unable to find address for the given coordinates" }
    end
  end
end
