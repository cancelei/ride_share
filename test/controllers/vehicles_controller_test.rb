require "test_helper"

class VehiclesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @vehicle = vehicles(:one)
  end

  test "should get index" do
    get vehicles_url
    assert_response :success
  end

  test "should get new" do
    get new_vehicle_url
    assert_response :success
  end

  test "should create vehicle" do
    assert_difference("Vehicle.count") do
      post vehicles_url, params: { vehicle: { brand: @vehicle.brand, built_year: @vehicle.built_year, color: @vehicle.color, driver_profile_id: @vehicle.driver_profile_id, fuel_avg: @vehicle.fuel_avg, has_private_insurance: @vehicle.has_private_insurance, model: @vehicle.model, registration_number: @vehicle.registration_number, seating_capacity: @vehicle.seating_capacity } }
    end

    assert_redirected_to vehicle_url(Vehicle.last)
  end

  test "should show vehicle" do
    get vehicle_url(@vehicle)
    assert_response :success
  end

  test "should get edit" do
    get edit_vehicle_url(@vehicle)
    assert_response :success
  end

  test "should update vehicle" do
    patch vehicle_url(@vehicle), params: { vehicle: { brand: @vehicle.brand, built_year: @vehicle.built_year, color: @vehicle.color, driver_profile_id: @vehicle.driver_profile_id, fuel_avg: @vehicle.fuel_avg, has_private_insurance: @vehicle.has_private_insurance, model: @vehicle.model, registration_number: @vehicle.registration_number, seating_capacity: @vehicle.seating_capacity } }
    assert_redirected_to vehicle_url(@vehicle)
  end

  test "should destroy vehicle" do
    assert_difference("Vehicle.count", -1) do
      delete vehicle_url(@vehicle)
    end

    assert_redirected_to vehicles_url
  end
end
