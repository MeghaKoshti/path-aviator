require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  def valid_params(**overrides)
    { user: { name: "Asha Rao", email_address: "asha@example.com", password: "long-enough-pw", password_confirmation: "long-enough-pw" }.merge(overrides) }
  end

  test "sign-up page has labelled fields and links to sign in" do
    get new_registration_path

    assert_response :success
    assert_select "h1", "Create your account"
    assert_select "label[for=user_name]", "Name (optional)"
    assert_select "label[for=user_email_address]", "Email"
    assert_select "input#user_password[autocomplete=new-password]"
    assert_select "label[for=user_password_confirmation]", "Confirm password"
    assert_select "a[href=?]", new_session_path, text: "Sign in"
  end

  test "sign-up shows the consent line with links to the terms and privacy policy" do
    get new_registration_path

    assert_select "form p", /By creating an account you agree to the\s+Terms\s+and\s+Privacy Policy/
    assert_select "form a[href=?]", terms_path, text: "Terms"
    assert_select "form a[href=?]", privacy_path, text: "Privacy Policy"
  end

  test "sign-in page links to sign-up" do
    get new_session_path

    assert_select "a[href=?]", new_registration_path, text: "Create an account"
  end

  test "signing up creates the user, starts a session and goes to onboarding" do
    assert_difference [ "User.count", "Session.count" ], 1 do
      post registration_path, params: valid_params
    end

    assert_redirected_to new_learning_goal_path
    assert cookies[:session_id].present?
    assert_equal "Asha Rao", User.last.name
  end

  test "name is optional" do
    assert_difference "User.count", 1 do
      post registration_path, params: valid_params(name: "")
    end
    assert_nil User.last.name
  end

  test "a duplicate email re-renders the form with an inline error" do
    assert_no_difference "User.count" do
      post registration_path, params: valid_params(email_address: users(:one).email_address.upcase)
    end

    assert_response :unprocessable_entity
    assert_select "input#user_email_address[aria-invalid=true][autofocus]"
    assert_select "#user_email_address_error", /already been taken/
    assert cookies[:session_id].blank?
  end

  test "mismatched passwords show an error on the confirmation field" do
    assert_no_difference "User.count" do
      post registration_path, params: valid_params(password_confirmation: "something-else")
    end

    assert_response :unprocessable_entity
    assert_select "#user_password_confirmation_error", /doesn't match/
    assert_select "[role=alert]", /1 thing needs fixing/
  end

  test "a short password is rejected" do
    post registration_path, params: valid_params(password: "short", password_confirmation: "short")

    assert_response :unprocessable_entity
    assert_select "#user_password_error", /too short/
  end

  test "sign-up attempts are rate limited after ten tries" do
    10.times do
      post registration_path, params: valid_params(password: "short", password_confirmation: "short")
      assert_response :unprocessable_entity
    end

    assert_no_difference "User.count" do
      post registration_path, params: valid_params
    end

    assert_redirected_to new_registration_url
    assert_equal "Too many sign-up attempts. Try again in a few minutes.", flash[:alert]
  end

  test "signed-in people are sent to their dashboard" do
    sign_in_as users(:one)

    get new_registration_path

    assert_redirected_to dashboard_path
  end
end
