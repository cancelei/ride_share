# app/services/google_places_service.rb
require "net/http"
require "json"

class GooglePlacesService
  GOOGLE_PLACES_API_V1_URL = "https://places.googleapis.com/v1/places".freeze
  GOOGLE_PLACES_AUTOCOMPLETE_URL = "https://maps.googleapis.com/maps/api/place/autocomplete/json".freeze
  GOOGLE_PLACE_DETAILS_API_URL = "https://maps.googleapis.com/maps/api/place/details/json".freeze
  GOOGLE_DISTANCE_MATRIX_API_URL = "https://maps.googleapis.com/maps/api/distancematrix/json".freeze

  def initialize
    @api_key = ENV["GOOGLE_MAPS_API_KEY"]
  end

  def text_search(query, options = {})
    uri = URI("#{GOOGLE_PLACES_API_V1_URL}:searchText")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    # Build the request body
    request_body = {
      textQuery: query,
      maxResultCount: options[:max_results] || 10,
      rankPreference: "DISTANCE",
      locationBias: build_location_bias(options)
    }.compact

    # Create the request
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["X-Goog-Api-Key"] = @api_key
    request["X-Goog-FieldMask"] = "places.displayName,places.formattedAddress,places.location,places.id"
    request.body = request_body.to_json

    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      Rails.logger.info("Google Places API V1 response: #{data.to_json}")

      data["places"]&.map do |place|
        {
          id: place["id"],
          name: place.dig("displayName", "text"),
          address: place["formattedAddress"],
          location: place["location"]
        }
      end || []
    else
      Rails.logger.error("Google Places Text Search API error: #{response.body}")
      []
    end
  end

  def autocomplete(query, options = {})
    uri = URI("#{GOOGLE_PLACES_API_V1_URL}:searchText")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    # Build the request body with more flexible search parameters
    request_body = {
      textQuery: query,
      maxResultCount: 5,
      rankPreference: "RELEVANCE",
      languageCode: "en",  # English for Honduras
      locationRestriction: {
        rectangle: {
          low: {
            latitude: 12.9842,   # Southernmost point of Honduras
            longitude: -89.3508  # Westernmost point of Honduras
          },
          high: {
            latitude: 16.5100,   # Northernmost point of Honduras
            longitude: -83.1555  # Easternmost point of Honduras
          }
        }
      }
    }

    # Create the request
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["X-Goog-Api-Key"] = @api_key
    request["X-Goog-FieldMask"] = "places.id,places.displayName,places.formattedAddress,places.location"
    request.body = request_body.to_json

    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      Rails.logger.info("Google Places API V1 response: #{data.to_json}")

      data["places"]&.map do |place|
        {
          id: place["id"],
          name: place.dig("displayName", "text"),
          address: place["formattedAddress"],
          location: {
            latitude: place.dig("location", "latitude"),
            longitude: place.dig("location", "longitude")
          },
          full_description: "#{place.dig('displayName', 'text')} - #{place['formattedAddress']}"
        }
      end || []
    else
      Rails.logger.error("Google Places API error: #{response.body}")
      []
    end
  rescue StandardError => e
    Rails.logger.error("Google Places API error: #{e.message}")
    []
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
    details = data.dig("result", "geometry", "location")
    details.present? ? { latitude: details["lat"], longitude: details["lng"] } : {}
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

  def fetch_distance_matrix(origin_lat, origin_lng, destination_lat, destination_lng)
    uri = URI(GOOGLE_DISTANCE_MATRIX_API_URL)
    params = {
      origins: "#{origin_lat},#{origin_lng}",
      destinations: "#{destination_lat},#{destination_lng}",
      mode: "driving",
      key: @api_key
    }

    uri.query = URI.encode_www_form(params)
    response = Net::HTTP.get_response(uri)
    data = JSON.parse(response.body)

    if data["status"] == "OK" && data["rows"].present? && data["rows"].first["elements"].present?
      element = data["rows"].first["elements"].first
      if element["status"] == "OK"
        {
          distance: {
            text: element["distance"]["text"],
            value: element["distance"]["value"]
          },
          duration: {
            text: element["duration"]["text"],
            value: element["duration"]["value"]
          },
          status: "OK"
        }
      else
        { status: element["status"], error: "Could not calculate distance" }
      end
    else
      { status: data["status"], error: "Distance Matrix API error" }
    end
  rescue StandardError => e
    Rails.logger.error("Google Distance Matrix API error: #{e.message}")
    { status: "ERROR", error: e.message }
  end

  private

  def build_location_bias(options)
    if options[:lat].present? && options[:lng].present?
      {
        circle: {
          center: {
            latitude: options[:lat],
            longitude: options[:lng]
          },
          radius: options[:radius] || 50000.0 # Default 50km radius
        }
      }
    elsif options[:bounds].present?
      {
        rectangle: {
          low: {
            latitude: options[:bounds][:south],
            longitude: options[:bounds][:west]
          },
          high: {
            latitude: options[:bounds][:north],
            longitude: options[:bounds][:east]
          }
        }
      }
    end
  end
end
