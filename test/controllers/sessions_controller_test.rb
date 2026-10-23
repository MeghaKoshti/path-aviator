require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "sign-in page renders labelled fields and no OAuth buttons" do
    get new_session_path

    assert_response :success
    assert_select "h1", "Welcome back"
    assert_select "label[for=email_address]", "Email"
    assert_select "label[for=password]", "Password"
    assert_select "a[href=?]", new_password_path
    assert_select "a[href^='/auth/']", false
    assert_no_match(/Google|GitHub/, response.body)
  end

  test "signing in with valid credentials starts a session" do
    sign_in_as users(:one)

    assert_redirected_to root_url
    assert cookies[:session_id].present?
  end

  test "a wrong password shows an alert toast" do
    sign_in_as users(:one), password: "wrong"
    follow_redirect!

    assert_select "[role=alert]", /Try another email address or password/
  end

  test "signing out ends the session" do
    sign_in_as users(:one)

    delete session_path

    assert_redirected_to new_session_path
    assert cookies[:session_id].blank?
  end
end
