# app/controllers/places_controller.rb
class PlacesController < ApplicationController
  def autocomplete
    locations = GooglePlacesService.new.autocomplete(params[:query])

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
