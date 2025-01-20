require "test_helper"

class RidesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ride = rides(:one)
  end

  test "should get index" do
    get rides_url
    assert_response :success
  end

  test "should get new" do
    get new_ride_url
    assert_response :success
  end

  test "should create ride" do
    assert_difference("Ride.count") do
      post rides_url, params: { ride: { available_seats: @ride.available_seats, discount: @ride.discount, distance: @ride.distance, driver_id: @ride.driver_id, dropoff: @ride.dropoff, estimated_time: @ride.estimated_time, invitation_code: @ride.invitation_code, pickup: @ride.pickup, price: @ride.price, rating: @ride.rating, review: @ride.review, ride_type: @ride.ride_type, scheduled_time: @ride.scheduled_time, status: @ride.status, time_taken: @ride.time_taken } }
    end

    assert_redirected_to ride_url(Ride.last)
  end

  test "should show ride" do
    get ride_url(@ride)
    assert_response :success
  end

  test "should get edit" do
    get edit_ride_url(@ride)
    assert_response :success
  end

  test "should update ride" do
    patch ride_url(@ride), params: { ride: { available_seats: @ride.available_seats, discount: @ride.discount, distance: @ride.distance, driver_id: @ride.driver_id, dropoff: @ride.dropoff, estimated_time: @ride.estimated_time, invitation_code: @ride.invitation_code, pickup: @ride.pickup, price: @ride.price, rating: @ride.rating, review: @ride.review, ride_type: @ride.ride_type, scheduled_time: @ride.scheduled_time, status: @ride.status, time_taken: @ride.time_taken } }
    assert_redirected_to ride_url(@ride)
  end

  test "should destroy ride" do
    assert_difference("Ride.count", -1) do
      delete ride_url(@ride)
    end

    assert_redirected_to rides_url
  end
end
