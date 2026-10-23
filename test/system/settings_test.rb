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
end
