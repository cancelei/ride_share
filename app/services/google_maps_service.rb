require "net/http"

class GoogleMapsService
  GOOGLE_MAPS_DIRECTIONS_API_URL = "https://maps.googleapis.com/maps/api/directions/json"

  def initialize
    @api_key = ENV["GOOGLE_MAPS_API_KEY"]
  end

  def directions(origin, destination, mode = "driving")
    Rails.logger.info "Fetching directions from #{origin} to #{destination} via #{mode}"
    uri = URI(GOOGLE_MAPS_DIRECTIONS_API_URL)
    params = {
      origin: origin,
      destination: destination,
      mode: mode,
      key: @api_key
    }
    uri.query = URI.encode_www_form(params)

    begin
      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        result = JSON.parse(response.body)
        Rails.logger.info "Directions API response status: #{result['status']}"

        # Return only what's needed by the frontend
        if result["status"] == "OK"
          route = result["routes"].first
          leg = route["legs"].first

          response_data = {
            status: "OK",
            distance: leg["distance"],
            duration: leg["duration"],
            start_location: leg["start_location"],
            end_location: leg["end_location"],
            steps: leg["steps"].map { |step|
              {
                distance: step["distance"],
                duration: step["duration"],
                start_location: step["start_location"],
                end_location: step["end_location"],
                html_instructions: step["html_instructions"],
                polyline: step["polyline"]
              }
            },
            overview_polyline: route["overview_polyline"],
            bounds: route["bounds"]
          }

          Rails.logger.info "Successfully processed directions data"
          response_data
        else
          Rails.logger.error "Directions API error: #{result['status']} - #{result['error_message']}"
          { status: result["status"], error_message: result["error_message"] }
        end
      else
        Rails.logger.error "Directions API HTTP error: #{response.code} - #{response.message}"
        { status: "REQUEST_DENIED", error_message: "Failed to fetch directions: #{response.message}" }
      end
    rescue => e
      Rails.logger.error "Exception fetching directions: #{e.message}"
      { status: "EXCEPTION", error_message: "Error fetching directions: #{e.message}" }
    end
  end
end
