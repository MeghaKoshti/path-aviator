require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "guests see the landing page" do
    get root_path

    assert_response :success
    assert_select "h1", /Chart a course/
    assert_select "a[href=?]", new_registration_path, text: "Plan my first path"
    assert_select "a[href=?]", new_session_path, text: "Sign in"
    assert_select "h2", "How it works"
    assert_select "a[href='#main']", "Skip to main content"
    assert_select "main#main"
  end

  test "signed-in users are sent to their dashboard" do
    sign_in_as users(:one)

    get root_path

    assert_redirected_to dashboard_path
  end
end
