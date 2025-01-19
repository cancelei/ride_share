require "test_helper"

class PassengerProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @passenger_profile = passenger_profiles(:one)
  end

  test "should get index" do
    get passenger_profiles_url
    assert_response :success
  end

  test "should get new" do
    get new_passenger_profile_url
    assert_response :success
  end

  test "should create passenger_profile" do
    assert_difference("PassengerProfile.count") do
      post passenger_profiles_url, params: { passenger_profile: { telegram_username: @passenger_profile.telegram_username, user_id: @passenger_profile.user_id, whatsapp_number: @passenger_profile.whatsapp_number } }
    end

    assert_redirected_to passenger_profile_url(PassengerProfile.last)
  end

  test "should show passenger_profile" do
    get passenger_profile_url(@passenger_profile)
    assert_response :success
  end

  test "should get edit" do
    get edit_passenger_profile_url(@passenger_profile)
    assert_response :success
  end

  test "should update passenger_profile" do
    patch passenger_profile_url(@passenger_profile), params: { passenger_profile: { telegram_username: @passenger_profile.telegram_username, user_id: @passenger_profile.user_id, whatsapp_number: @passenger_profile.whatsapp_number } }
    assert_redirected_to passenger_profile_url(@passenger_profile)
  end

  test "should destroy passenger_profile" do
    assert_difference("PassengerProfile.count", -1) do
      delete passenger_profile_url(@passenger_profile)
    end

    assert_redirected_to passenger_profiles_url
  end
end
