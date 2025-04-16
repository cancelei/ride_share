# app/controllers/places_controller.rb
class PlacesController < ApplicationController
  def autocomplete
    options = {}

    # For dropoff suggestions, prioritize pickup location if available
    if params[:for_dropoff].present? && params[:pickup_lat].present? && params[:pickup_lng].present?
      options[:lat] = params[:pickup_lat]
      options[:lng] = params[:pickup_lng]
    # If no pickup but user location is available, use that
    elsif params[:user_lat].present? && params[:user_lng].present?
      options[:lat] = params[:user_lat]
      options[:lng] = params[:user_lng]
    end

    locations = GooglePlacesService.new.autocomplete(params[:query], options)

    render json: locations
  end

  def details
    place_details = GooglePlacesService.new.details(params["place_id"])

    render json: place_details
  end

  def reverse_geocode
    unless params[:lat].present? && params[:lng].present?
      return render json: { error: "Latitude and longitude are required" }, status: :bad_request
    end

    address_data = GooglePlacesService.new.reverse_geocode(params[:lat], params[:lng])

    render json: address_data
  end
end
