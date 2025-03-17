# app/controllers/places_controller.rb
class PlacesController < ApplicationController
  def autocomplete
    locations = GooglePlacesService.new.autocomplete(params[:query])

    render json: locations
  end
end
