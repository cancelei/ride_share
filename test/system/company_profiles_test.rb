require "application_system_test_case"

class CompanyProfilesTest < ApplicationSystemTestCase
  setup do
    @company_profile = company_profiles(:one)
  end

  test "visiting the index" do
    visit company_profiles_url
    assert_selector "h1", text: "Company profiles"
  end

  test "should create company profile" do
    visit company_profiles_url
    click_on "New company profile"

    fill_in "Description", with: @company_profile.description
    fill_in "Name", with: @company_profile.name
    fill_in "Telegram number", with: @company_profile.telegram_number
    fill_in "Whatsapp number", with: @company_profile.whatsapp_number
    click_on "Create Company profile"

    assert_text "Company profile was successfully created"
    click_on "Back"
  end

  test "should update Company profile" do
    visit company_profile_url(@company_profile)
    click_on "Edit this company profile", match: :first

    fill_in "Description", with: @company_profile.description
    fill_in "Name", with: @company_profile.name
    fill_in "Telegram number", with: @company_profile.telegram_number
    fill_in "Whatsapp number", with: @company_profile.whatsapp_number
    click_on "Update Company profile"

    assert_text "Company profile was successfully updated"
    click_on "Back"
  end

  test "should destroy Company profile" do
    visit company_profile_url(@company_profile)
    click_on "Destroy this company profile", match: :first

    assert_text "Company profile was successfully destroyed"
  end
end
