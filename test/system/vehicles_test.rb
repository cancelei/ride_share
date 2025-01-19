require "application_system_test_case"

class VehiclesTest < ApplicationSystemTestCase
  setup do
    @vehicle = vehicles(:one)
  end

  test "visiting the index" do
    visit vehicles_url
    assert_selector "h1", text: "Vehicles"
  end

  test "should create vehicle" do
    visit vehicles_url
    click_on "New vehicle"

    fill_in "Brand", with: @vehicle.brand
    fill_in "Built year", with: @vehicle.built_year
    fill_in "Color", with: @vehicle.color
    fill_in "Driver profile", with: @vehicle.driver_profile_id
    fill_in "Fuel avg", with: @vehicle.fuel_avg
    check "Has private insurance" if @vehicle.has_private_insurance
    fill_in "Model", with: @vehicle.model
    fill_in "Registration number", with: @vehicle.registration_number
    fill_in "Seating capacity", with: @vehicle.seating_capacity
    click_on "Create Vehicle"

    assert_text "Vehicle was successfully created"
    click_on "Back"
  end

  test "should update Vehicle" do
    visit vehicle_url(@vehicle)
    click_on "Edit this vehicle", match: :first

    fill_in "Brand", with: @vehicle.brand
    fill_in "Built year", with: @vehicle.built_year
    fill_in "Color", with: @vehicle.color
    fill_in "Driver profile", with: @vehicle.driver_profile_id
    fill_in "Fuel avg", with: @vehicle.fuel_avg
    check "Has private insurance" if @vehicle.has_private_insurance
    fill_in "Model", with: @vehicle.model
    fill_in "Registration number", with: @vehicle.registration_number
    fill_in "Seating capacity", with: @vehicle.seating_capacity
    click_on "Update Vehicle"

    assert_text "Vehicle was successfully updated"
    click_on "Back"
  end

  test "should destroy Vehicle" do
    visit vehicle_url(@vehicle)
    click_on "Destroy this vehicle", match: :first

    assert_text "Vehicle was successfully destroyed"
  end
end
