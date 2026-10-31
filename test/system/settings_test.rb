require "application_system_test_case"

class SettingsTest < ApplicationSystemTestCase
  test "reaching settings from the account menu and changing the name" do
    sign_in_through_ui users(:one)

    click_on "Account menu for"
    click_on "Settings"
    fill_in "Name (optional)", with: "Riya K"
    click_on "Save profile"

    assert_text "Profile saved."
    assert_selector "header", text: "Riya K"
  end

  test "the demo account sees its settings locked" do
    demo = DemoAccount.reset!
    sign_in_through_ui demo, password: DemoAccount::PASSWORD
    visit settings_path

    assert_text SettingsController::DEMO_LOCKED_NOTICE
    assert_field "Name (optional)", with: "Demo Learner", disabled: true
    assert_field "New password", disabled: true
    assert_button "Save profile", disabled: true
    assert_button "Change password", disabled: true
    assert_button "Delete my account", disabled: true
  end
end
