require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "requires sign-in" do
    delete session_path
    get settings_path
    assert_redirected_to new_session_path
  end

  test "shows profile, password and delete sections with unique, labelled fields" do
    get settings_path

    assert_response :success
    assert_select "h1", "Settings"
    assert_select "form[action=?]", settings_profile_path do
      assert_select "label[for=profile_user_name]", "Name (optional)"
      assert_select "input#profile_user_email_address[value=?]", @user.email_address
      assert_select "input#profile_user_password_challenge[type=password]:not([value])"
    end
    assert_select "form[action=?]", settings_password_path do
      assert_select "label[for=password_change_user_password_challenge]", "Current password"
      assert_select "input#password_change_user_password[autocomplete=new-password]"
    end
    assert_select "form[action=?] input[name=_method][value=delete]", settings_account_path
    assert_select "label[for=confirmation]", "Type DELETE or your email to confirm"
    assert_select "p", /2 learning paths/
    assert_select "#demo-locked-note", 0
    assert_select "fieldset[disabled]", 0
  end

  # Profile

  test "updating the name doesn't need the current password" do
    patch settings_profile_path, params: { user: { name: "Riya S", email_address: @user.email_address } }

    assert_redirected_to settings_path
    assert_equal "Riya S", @user.reload.name
  end

  test "changing the email without the current password is refused" do
    patch settings_profile_path, params: { user: { name: @user.name, email_address: "new@example.com" } }

    assert_response :unprocessable_entity
    assert_select "#profile_user_password_challenge_error", "Current password is needed to change your email"
    assert_select "input#profile_user_password_challenge[autofocus]"
    assert_equal "one@example.com", @user.reload.email_address
    assert_select "#account-menu", text: /one@example.com/
  end

  test "changing the email with a wrong current password is refused" do
    patch settings_profile_path, params: { user: { email_address: "new@example.com", password_challenge: "wrong-password" } }

    assert_response :unprocessable_entity
    assert_select "#profile_user_password_challenge_error", "Current password is incorrect"
    assert_equal "one@example.com", @user.reload.email_address
  end

  test "changing the email with the current password works" do
    patch settings_profile_path, params: { user: { email_address: " New@Example.com ", password_challenge: "password" } }

    assert_redirected_to settings_path
    assert_equal "new@example.com", @user.reload.email_address
  end

  test "an email that's already taken shows an inline error" do
    patch settings_profile_path, params: { user: { email_address: users(:two).email_address, password_challenge: "password" } }

    assert_response :unprocessable_entity
    assert_select "#profile_user_email_address_error", /already been taken/
  end

  # Password

  test "changing the password signs out other sessions but keeps this one" do
    other = @user.sessions.create!(user_agent: "Other laptop", ip_address: "10.0.0.2")

    patch settings_password_path, params: { user: { password_challenge: "password", password: "brand-new-pw", password_confirmation: "brand-new-pw" } }

    assert_redirected_to settings_path
    assert_not Session.exists?(other.id)
    assert_equal 1, @user.sessions.count
    assert @user.reload.authenticate("brand-new-pw")
    follow_redirect!
    assert_response :success
  end

  test "a wrong current password doesn't change the password" do
    patch settings_password_path, params: { user: { password_challenge: "nope", password: "brand-new-pw", password_confirmation: "brand-new-pw" } }

    assert_response :unprocessable_entity
    assert_select "#password_change_user_password_challenge_error", "Current password is incorrect"
    assert @user.reload.authenticate("password")
  end

  test "the new password must be confirmed, long enough and present" do
    patch settings_password_path, params: { user: { password_challenge: "password", password: "brand-new-pw", password_confirmation: "different" } }
    assert_response :unprocessable_entity
    assert_select "#password_change_user_password_confirmation_error", /doesn't match/

    patch settings_password_path, params: { user: { password_challenge: "password", password: "short", password_confirmation: "short" } }
    assert_select "#password_change_user_password_error", /too short/

    patch settings_password_path, params: { user: { password_challenge: "password", password: "", password_confirmation: "" } }
    assert_select "#password_change_user_password_error", /can't be blank/
    assert @user.reload.authenticate("password")
  end

  # Account deletion

  test "deleting needs DELETE or the account email" do
    assert_no_difference "User.count" do
      delete settings_account_path, params: { confirmation: "delete please" }
    end

    assert_response :unprocessable_entity
    assert_select "#confirmation_error", /Type DELETE or your email/
    assert_select "input#confirmation[autofocus][aria-invalid=true]"
  end

  test "typing DELETE removes the account and everything in it" do
    @user.sessions.create!(user_agent: "Other laptop", ip_address: "10.0.0.2")

    assert_difference -> { User.count } => -1, -> { LearningGoal.count } => -2,
                      -> { LearningPath.count } => -2, -> { PathStep.count } => -4, -> { Session.count } => -2 do
      delete settings_account_path, params: { confirmation: "DELETE" }
    end

    assert_redirected_to root_path
    assert cookies[:session_id].blank?
    follow_redirect!
    assert_select "[role=status]", /Your account and all your paths have been deleted/
  end

  test "typing the account email (any case) also confirms" do
    assert_difference "User.count", -1 do
      delete settings_account_path, params: { confirmation: " ONE@example.com " }
    end
  end

  test "time zone and weekly email can be changed" do
    get settings_path
    assert_select "form[action=?]", settings_preferences_path do
      assert_select "select#preferences_user_time_zone option[value='Asia/Kolkata']", /Kolkata/
      assert_select "input[type=checkbox]#preferences_user_weekly_digest[checked]"
    end

    patch settings_preferences_path, params: { user: { time_zone: "Asia/Kolkata", weekly_digest: "0" } }

    assert_redirected_to settings_path(anchor: "preferences")
    @user.reload
    assert_equal "Asia/Kolkata", @user.time_zone
    assert_not @user.weekly_digest?
  end

  test "pages show dates in the user's own zone" do
    @user.update!(time_zone: "Asia/Kolkata")

    # Sunday 20:00 UTC is Monday 01:30 in Kolkata: a new week has started there.
    travel_to Time.utc(2026, 11, 1, 20, 0) do
      get dashboard_path
      assert_select "#learning_stats", /2 Nov to 8 Nov/

      @user.update!(time_zone: "UTC")
      get dashboard_path
      assert_select "#learning_stats", /26 Oct to 1 Nov/
    end
  end

  test "the demo account can't change its preferences" do
    demo = DemoAccount.reset!
    sign_in_as demo, password: DemoAccount::PASSWORD

    patch settings_preferences_path, params: { user: { time_zone: "Asia/Tokyo" } }

    assert_redirected_to settings_path
    assert_equal "UTC", demo.reload.time_zone
  end
end
