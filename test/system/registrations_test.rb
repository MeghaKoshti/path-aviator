require "application_system_test_case"

class RegistrationsTest < ApplicationSystemTestCase
  test "signing up from the landing page lands on onboarding" do
    visit root_path
    click_on "Get started"

    assert_text "By creating an account you agree to the Terms and Privacy Policy."
    within("form") { click_on "Privacy Policy" }
    assert_selector "h1", text: "Privacy Policy"
    go_back

    fill_in "Name (optional)", with: "Asha Rao"
    fill_in "Email", with: "asha@example.com"
    fill_in "Password", with: "long-enough-pw"
    fill_in "Confirm password", with: "long-enough-pw"
    click_on "Create account"

    assert_text "Welcome aboard"
    assert_current_path new_learning_goal_path
  end

  test "sign-up stores the time zone the browser reports" do
    visit new_registration_path
    browser_zone = evaluate_script("Intl.DateTimeFormat().resolvedOptions().timeZone")
    assert_equal browser_zone, find("#user_time_zone", visible: :hidden).value

    # Stand in for a learner in India, whatever zone this machine is in.
    execute_script("document.getElementById('user_time_zone').value = 'Asia/Kolkata'")
    fill_in "Email", with: "zone@example.com"
    fill_in "Password", with: "long-enough-pw"
    fill_in "Confirm password", with: "long-enough-pw"
    click_on "Create account"

    assert_current_path new_learning_goal_path
    assert_equal "Asia/Kolkata", User.find_by(email_address: "zone@example.com").time_zone
  end
end
