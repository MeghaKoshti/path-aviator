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
    assert_button "Save preferences", disabled: true
    assert_button "Delete my account", disabled: true
  end

  test "changing the time zone and turning off the weekly email" do
    sign_in_through_ui users(:one)
    visit settings_path

    select "(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi", from: "Time zone"
    uncheck "Weekly check-in email"
    click_on "Save preferences"

    assert_text "Preferences saved."
    assert_select "Time zone", selected: "(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi"
    assert_equal "Asia/Kolkata", users(:one).reload.time_zone
    assert_not users(:one).weekly_digest?
  end
end
