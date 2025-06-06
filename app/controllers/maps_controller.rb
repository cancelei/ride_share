class MapsController < ApplicationController
  def directions
    return head :bad_request unless params[:origin] && params[:destination]

    # Check if we should include alternative routes
    alternatives = params[:alternatives] == "true"

    directions_data = GoogleMapsService.new.directions(
      params[:origin],
      params[:destination],
      params[:mode] || "driving",
      alternatives
    )

    render json: directions_data
  end

  def map_details
    # Create a script URL that includes the API key server-side
    # This way, we never expose the raw API key to the client
    api_key = ENV["GOOGLE_MAPS_API_KEY"]
    # For AdvancedMarkers, either use a configured Map ID or provide a default one
    map_id = ENV["GOOGLE_MAPS_MAP_ID"].presence || "8e0a97af9386fef"

    script_url = "https://maps.googleapis.com/maps/api/js?key=#{api_key}&libraries=places,geometry,marker&callback=initGoogleMaps&loading=async&v=beta&map_id=#{map_id}"

    # Return the script URL and other settings
    render json: {
      script_url: script_url,
      config: {
        libraries: "places,geometry,marker",
        mapId: map_id,
        region: "hn" # Adjust as needed for your region
      }
    }
  end

  def traffic_info
    return head :bad_request unless params[:location]

    traffic_data = GoogleMapsService.new.traffic_info(params[:location])

    render json: traffic_data
  end
end
