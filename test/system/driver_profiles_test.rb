require "application_system_test_case"

class DriverProfilesTest < ApplicationSystemTestCase
  setup do
    @driver_profile = driver_profiles(:one)
  end

  test "visiting the index" do
    visit driver_profiles_url
    assert_selector "h1", text: "Driver profiles"
  end

  test "should create driver profile" do
    visit driver_profiles_url
    click_on "New driver profile"

    fill_in "License", with: @driver_profile.license
    fill_in "License issuer", with: @driver_profile.license_issuer
    fill_in "User", with: @driver_profile.user_id
    click_on "Create Driver profile"

    assert_text "Driver profile was successfully created"
    click_on "Back"
  end

  test "should update Driver profile" do
    visit driver_profile_url(@driver_profile)
    click_on "Edit this driver profile", match: :first

    fill_in "License", with: @driver_profile.license
    fill_in "License issuer", with: @driver_profile.license_issuer
    fill_in "User", with: @driver_profile.user_id
    click_on "Update Driver profile"

    assert_text "Driver profile was successfully updated"
    click_on "Back"
  end

  test "should destroy Driver profile" do
    visit driver_profile_url(@driver_profile)
    click_on "Destroy this driver profile", match: :first

    assert_text "Driver profile was successfully destroyed"
  end
end
