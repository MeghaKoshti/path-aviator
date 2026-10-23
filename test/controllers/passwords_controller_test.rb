require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "reset request page renders" do
    get new_password_path

    assert_response :success
    assert_select "h1", "Reset your password"
    assert_select "input[type=email][name=email_address][required]"
  end

  test "requesting a reset shows a notice" do
    post passwords_path, params: { email_address: users(:one).email_address }
    follow_redirect!

    assert_select "[role=status]", /Password reset instructions sent/
  end

  test "reset form renders for a valid token" do
    get edit_password_path(users(:one).password_reset_token)

    assert_response :success
    assert_select "h1", "Choose a new password"
    assert_select "label[for=password]", "New password"
    assert_select "label[for=password_confirmation]", "Confirm new password"
  end

  test "an invalid token sends people back to request a new link" do
    get edit_password_path("not-a-token")

    assert_redirected_to new_password_path
  end

  test "resetting the password signs out every existing session" do
    user = users(:one)
    sign_in_as user
    token = user.password_reset_token

    put password_path(token), params: { password: "a-brand-new-pw", password_confirmation: "a-brand-new-pw" }

    assert_redirected_to new_session_path
    assert user.reload.authenticate("a-brand-new-pw")
    assert_empty user.sessions
    get dashboard_path
    assert_redirected_to new_session_path
  end

  test "a short or mismatched new password explains what's wrong" do
    token = users(:one).password_reset_token

    put password_path(token), params: { password: "short", password_confirmation: "short" }
    assert_redirected_to edit_password_path(token)
    assert_equal "Password is too short (minimum is 8 characters)", flash[:alert]

    put password_path(token), params: { password: "a-brand-new-pw", password_confirmation: "something-else" }
    assert_equal "Password confirmation doesn't match Password", flash[:alert]
  end

  test "a blank new password is refused instead of reported as reset" do
    token = users(:one).password_reset_token

    put password_path(token), params: { password: "", password_confirmation: "" }

    assert_redirected_to edit_password_path(token)
    assert_equal "Enter a new password.", flash[:alert]
  end
end
