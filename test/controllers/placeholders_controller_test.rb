require "test_helper"

class PlaceholdersControllerTest < ActionDispatch::IntegrationTest
  test "settings requires sign-in" do
    get settings_path
    assert_redirected_to new_session_path
  end

  test "settings placeholder renders for signed-in users" do
    sign_in_as users(:one)
    get settings_path
    assert_response :success
  end
end
