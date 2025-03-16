# app/controllers/places_controller.rb
class PlacesController < ApplicationController
  def autocomplete
    places_service = GooglePlacesService.new(ENV["GOOGLE_MAPS_API_KEY"])
    locations = places_service.autocomplete(params[:query])

    render json: locations
  end
end
