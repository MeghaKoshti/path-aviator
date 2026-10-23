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
end
