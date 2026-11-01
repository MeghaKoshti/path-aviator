require "application_system_test_case"

class PricingTest < ApplicationSystemTestCase
  test "switching between monthly and yearly, rupees and dollars" do
    visit pricing_path(currency: "usd")

    within("[aria-labelledby=pro-plan]") { assert_text "$6\nper month" }

    click_on "Yearly"
    assert_selector "button[aria-pressed=true]", text: "Yearly"
    assert_selector "button[aria-pressed=false]", text: "Monthly"
    within("[aria-labelledby=pro-plan]") do
      assert_text "$48"
      assert_text "Billed yearly, about $4 a month."
      assert_no_text "$6"
    end

    click_on "₹ INR"
    within("[aria-labelledby=pro-plan]") { assert_text "₹1,499" }
    assert_selector "[aria-labelledby=free-plan]", text: "₹0"

    # The currency choice is remembered for the next visit.
    visit pricing_path
    assert_selector "button[aria-pressed=true]", text: "₹ INR"
  end

  test "the toggles work from the keyboard" do
    visit pricing_path(currency: "usd")

    find("button", text: "Monthly").send_keys(:tab)
    page.driver.browser.action.send_keys(:enter).perform
    within("[aria-labelledby=pro-plan]") { assert_text "$48" }
  end
end
