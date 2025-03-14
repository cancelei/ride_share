require "application_system_test_case"

class BookingsTest < ApplicationSystemTestCase
  setup do
    @booking = bookings(:one)
  end

  test "visiting the index" do
    visit bookings_url
    assert_selector "h1", text: "Bookings"
  end

  test "should create booking" do
    visit bookings_url
    click_on "New booking"

    fill_in "Dropoff", with: @booking.dropoff
    fill_in "Passenger", with: @booking.passenger_id
    fill_in "Pickup", with: @booking.pickup
    fill_in "Requested seats", with: @booking.requested_seats
    fill_in "Scheduled time", with: @booking.scheduled_time
    fill_in "Special instructions", with: @booking.special_instructions
    fill_in "Status", with: @booking.status
    click_on "Create Booking"

    assert_text "Booking was successfully created"
    click_on "Back"
  end

  test "should update Booking" do
    visit booking_url(@booking)
    click_on "Edit this booking", match: :first

    fill_in "Dropoff", with: @booking.dropoff
    fill_in "Passenger", with: @booking.passenger_id
    fill_in "Pickup", with: @booking.pickup
    fill_in "Requested seats", with: @booking.requested_seats
    fill_in "Scheduled time", with: @booking.scheduled_time.to_s
    fill_in "Special instructions", with: @booking.special_instructions
    fill_in "Status", with: @booking.status
    click_on "Update Booking"

    assert_text "Booking was successfully updated"
    click_on "Back"
  end

  test "should destroy Booking" do
    visit booking_url(@booking)
    click_on "Destroy this booking", match: :first

    assert_text "Booking was successfully destroyed"
  end
end
