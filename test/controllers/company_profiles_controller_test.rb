require "test_helper"

class CompanyProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @company_profile = company_profiles(:one)
  end

  test "should get index" do
    get company_profiles_url
    assert_response :success
  end

  test "should get new" do
    get new_company_profile_url
    assert_response :success
  end

  test "should create company_profile" do
    assert_difference("CompanyProfile.count") do
      post company_profiles_url, params: { company_profile: { description: @company_profile.description, name: @company_profile.name, telegram_number: @company_profile.telegram_number, whatsapp_number: @company_profile.whatsapp_number } }
    end

    assert_redirected_to company_profile_url(CompanyProfile.last)
  end

  test "should show company_profile" do
    get company_profile_url(@company_profile)
    assert_response :success
  end

  test "should get edit" do
    get edit_company_profile_url(@company_profile)
    assert_response :success
  end

  test "should update company_profile" do
    patch company_profile_url(@company_profile), params: { company_profile: { description: @company_profile.description, name: @company_profile.name, telegram_number: @company_profile.telegram_number, whatsapp_number: @company_profile.whatsapp_number } }
    assert_redirected_to company_profile_url(@company_profile)
  end

  test "should destroy company_profile" do
    assert_difference("CompanyProfile.count", -1) do
      delete company_profile_url(@company_profile)
    end

    assert_redirected_to company_profiles_url
  end
end
