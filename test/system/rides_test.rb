require "application_system_test_case"

class RidesTest < ApplicationSystemTestCase
  setup do
    @ride = rides(:one)
  end

  test "visiting the index" do
    visit rides_url
    assert_selector "h1", text: "Rides"
  end

  test "should create ride" do
    visit rides_url
    click_on "New ride"

    fill_in "Available seats", with: @ride.available_seats
    fill_in "Discount", with: @ride.discount
    fill_in "Distance", with: @ride.distance
    fill_in "Driver", with: @ride.driver_id
    fill_in "Dropoff", with: @ride.dropoff
    fill_in "Estimated time", with: @ride.estimated_time
    fill_in "Invitation code", with: @ride.invitation_code
    fill_in "Pickup", with: @ride.pickup
    fill_in "Price", with: @ride.price
    fill_in "Rating", with: @ride.rating
    fill_in "Review", with: @ride.review
    fill_in "Ride type", with: @ride.ride_type
    fill_in "Scheduled time", with: @ride.scheduled_time
    fill_in "Status", with: @ride.status
    fill_in "Time taken", with: @ride.time_taken
    click_on "Create Ride"

    assert_text "Ride was successfully created"
    click_on "Back"
  end

  test "should update Ride" do
    visit ride_url(@ride)
    click_on "Edit this ride", match: :first

    fill_in "Available seats", with: @ride.available_seats
    fill_in "Discount", with: @ride.discount
    fill_in "Distance", with: @ride.distance
    fill_in "Driver", with: @ride.driver_id
    fill_in "Dropoff", with: @ride.dropoff
    fill_in "Estimated time", with: @ride.estimated_time
    fill_in "Invitation code", with: @ride.invitation_code
    fill_in "Pickup", with: @ride.pickup
    fill_in "Price", with: @ride.price
    fill_in "Rating", with: @ride.rating
    fill_in "Review", with: @ride.review
    fill_in "Ride type", with: @ride.ride_type
    fill_in "Scheduled time", with: @ride.scheduled_time.to_s
    fill_in "Status", with: @ride.status
    fill_in "Time taken", with: @ride.time_taken
    click_on "Update Ride"

    assert_text "Ride was successfully updated"
    click_on "Back"
  end

  test "should destroy Ride" do
    visit ride_url(@ride)
    click_on "Destroy this ride", match: :first

    assert_text "Ride was successfully destroyed"
  end
end
