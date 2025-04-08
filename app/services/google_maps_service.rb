require "net/http"

class GoogleMapsService
  GOOGLE_MAPS_DIRECTIONS_API_URL = "https://maps.googleapis.com/maps/api/directions/json"
  GOOGLE_MAPS_TRAFFIC_API_URL = "https://maps.googleapis.com/maps/api/distancematrix/json"

  def initialize
    @api_key = ENV["GOOGLE_MAPS_API_KEY"]
    puts "API Key: #{@api_key}"
  end

  def directions(origin, destination, mode = "driving", alternatives = false)
    Rails.logger.info "Fetching directions from #{origin} to #{destination} via #{mode} (alternatives: #{alternatives})"
    uri = URI(GOOGLE_MAPS_DIRECTIONS_API_URL)
    params = {
      origin: origin,
      destination: destination,
      mode: mode,
      alternatives: alternatives,
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
          # Process the primary route
          primary_route = result["routes"].first
          primary_leg = primary_route["legs"].first

          response_data = {
            status: "OK",
            distance: primary_leg["distance"],
            duration: primary_leg["duration"],
            start_location: primary_leg["start_location"],
            end_location: primary_leg["end_location"],
            steps: primary_leg["steps"].map { |step|
              {
                distance: step["distance"],
                duration: step["duration"],
                start_location: step["start_location"],
                end_location: step["end_location"],
                html_instructions: step["html_instructions"],
                polyline: step["polyline"]
              }
            },
            overview_polyline: primary_route["overview_polyline"],
            bounds: primary_route["bounds"]
          }

          # Process alternative routes if requested and available
          if alternatives && result["routes"].length > 1
            response_data[:alternative_routes] = result["routes"][1..-1].map do |route|
              leg = route["legs"].first
              {
                distance: leg["distance"],
                duration: leg["duration"],
                start_location: leg["start_location"],
                end_location: leg["end_location"],
                overview_polyline: route["overview_polyline"],
                bounds: route["bounds"],
                legs: route["legs"]
              }
            end
          end

          Rails.logger.info "Successfully processed directions data with #{response_data[:alternative_routes]&.length || 0} alternative routes"
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

  def traffic_info(location)
    Rails.logger.info "Fetching traffic information for #{location}"
    uri = URI(GOOGLE_MAPS_TRAFFIC_API_URL)

    # Get current time
    now = Time.now

    # Calculate departure time for 15 minutes from now
    departure_time = now + 15.minutes

    params = {
      origins: location,
      destinations: location,
      departure_time: departure_time.to_i,
      key: @api_key
    }
    uri.query = URI.encode_www_form(params)

    begin
      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        result = JSON.parse(response.body)
        Rails.logger.info "Traffic API response status: #{result['status']}"

        if result["status"] == "OK"
          # Extract traffic information
          row = result["rows"].first
          element = row["elements"].first

          traffic_data = {
            status: "OK",
            duration_in_traffic: element["duration_in_traffic"],
            duration: element["duration"],
            distance: element["distance"]
          }

          Rails.logger.info "Successfully processed traffic data"
          traffic_data
        else
          Rails.logger.error "Traffic API error: #{result['status']} - #{result['error_message']}"
          { status: result["status"], error_message: result["error_message"] }
        end
      else
        Rails.logger.error "Traffic API HTTP error: #{response.code} - #{response.message}"
        { status: "REQUEST_DENIED", error_message: "Failed to fetch traffic info: #{response.message}" }
      end
    rescue => e
      Rails.logger.error "Exception fetching traffic info: #{e.message}"
      { status: "EXCEPTION", error_message: "Error fetching traffic info: #{e.message}" }
    end
  end
end
