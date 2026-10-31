require "application_system_test_case"

class RegistrationsTest < ApplicationSystemTestCase
  test "signing up from the landing page lands on onboarding" do
    visit root_path
    click_on "Get started"

    fill_in "Name (optional)", with: "Asha Rao"
    fill_in "Email", with: "asha@example.com"
    fill_in "Password", with: "long-enough-pw"
    fill_in "Confirm password", with: "long-enough-pw"
    click_on "Create account"

    assert_text "Welcome aboard"
    assert_current_path new_learning_goal_path
  end
end
