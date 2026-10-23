require "test_helper"

class PlaceholdersControllerTest < ActionDispatch::IntegrationTest
  test "app pages require sign-in" do
    [ dashboard_path, new_learning_goal_path, settings_path ].each do |path|
      get path
      assert_redirected_to new_session_path
    end
  end

  test "signed-in app shell has the main navigation and account menu" do
    sign_in_as users(:one)

    get dashboard_path

    assert_response :success
    assert_select "nav[aria-label=Main] a[href=?][aria-current=page]", dashboard_path, text: "Dashboard"
    assert_select "nav[aria-label=Main] a[href=?]", new_learning_goal_path, text: "New path"
    assert_select "#account-menu a[href=?]", settings_path, text: "Settings"
    assert_select "#account-menu form[action=?] button", session_path, text: "Sign out"
    assert_select "button[aria-controls=mobile-menu][aria-expanded=false]"
    assert_select "a[href='#main']", "Skip to main content"
  end

  test "placeholder pages render for signed-in users" do
    sign_in_as users(:one)

    [ new_learning_goal_path, settings_path ].each do |path|
      get path
      assert_response :success
    end
  end

  test "registration placeholder is public" do
    get new_registration_path

    assert_response :success
    assert_select "a[href=?]", new_session_path, text: "Sign in"
  end
end
