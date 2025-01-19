require "test_helper"

class DriverProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @driver_profile = driver_profiles(:one)
  end

  test "should get index" do
    get driver_profiles_url
    assert_response :success
  end

  test "should get new" do
    get new_driver_profile_url
    assert_response :success
  end

  test "should create driver_profile" do
    assert_difference("DriverProfile.count") do
      post driver_profiles_url, params: { driver_profile: { license: @driver_profile.license, license_issuer: @driver_profile.license_issuer, user_id: @driver_profile.user_id } }
    end

    assert_redirected_to driver_profile_url(DriverProfile.last)
  end

  test "should show driver_profile" do
    get driver_profile_url(@driver_profile)
    assert_response :success
  end

  test "should get edit" do
    get edit_driver_profile_url(@driver_profile)
    assert_response :success
  end

  test "should update driver_profile" do
    patch driver_profile_url(@driver_profile), params: { driver_profile: { license: @driver_profile.license, license_issuer: @driver_profile.license_issuer, user_id: @driver_profile.user_id } }
    assert_redirected_to driver_profile_url(@driver_profile)
  end

  test "should destroy driver_profile" do
    assert_difference("DriverProfile.count", -1) do
      delete driver_profile_url(@driver_profile)
    end

    assert_redirected_to driver_profiles_url
  end
end
