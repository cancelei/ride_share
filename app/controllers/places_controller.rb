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
end
