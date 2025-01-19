require "application_system_test_case"

class PassengerProfilesTest < ApplicationSystemTestCase
  setup do
    @passenger_profile = passenger_profiles(:one)
  end

  test "visiting the index" do
    visit passenger_profiles_url
    assert_selector "h1", text: "Passenger profiles"
  end

  test "should create passenger profile" do
    visit passenger_profiles_url
    click_on "New passenger profile"

    fill_in "Telegram username", with: @passenger_profile.telegram_username
    fill_in "User", with: @passenger_profile.user_id
    fill_in "Whatsapp number", with: @passenger_profile.whatsapp_number
    click_on "Create Passenger profile"

    assert_text "Passenger profile was successfully created"
    click_on "Back"
  end

  test "should update Passenger profile" do
    visit passenger_profile_url(@passenger_profile)
    click_on "Edit this passenger profile", match: :first

    fill_in "Telegram username", with: @passenger_profile.telegram_username
    fill_in "User", with: @passenger_profile.user_id
    fill_in "Whatsapp number", with: @passenger_profile.whatsapp_number
    click_on "Update Passenger profile"

    assert_text "Passenger profile was successfully updated"
    click_on "Back"
  end

  test "should destroy Passenger profile" do
    visit passenger_profile_url(@passenger_profile)
    click_on "Destroy this passenger profile", match: :first

    assert_text "Passenger profile was successfully destroyed"
  end
end
