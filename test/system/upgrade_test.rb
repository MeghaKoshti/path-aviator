require "application_system_test_case"

class UpgradeTest < ApplicationSystemTestCase
  test "a free user upgrades from the pricing page through the fake checkout and comes back as Pro" do
    sign_in_through_ui users(:two)
    visit dashboard_path
    within("#plan_usage") { click_on "Upgrade to Pro" }

    assert_current_path pricing_path
    # An explicit choice, so the browser's time zone can't switch currencies.
    visit pricing_path(currency: "usd")
    click_on "Upgrade to Pro"

    assert_text "Test checkout"
    click_on "Pay $6 (test)"

    assert_selector "h1", text: "You’re on Pro"
    assert users(:two).reload.pro?
    assert_equal 1, Event.named(:upgraded).where(user: users(:two)).count

    visit dashboard_path
    within("#plan_usage") do
      assert_selector "span", text: "Pro"
      assert_no_link "Upgrade to Pro"
    end

    visit settings_path
    within("#subscription") do
      assert_text "Pro, monthly"
      assert_text "Renews on"
      click_on "Manage or cancel"
    end
    assert_text "Test billing portal"
    accept_confirm { click_on "Cancel subscription" }
    assert_text "Subscription cancelled."
    assert_text "You keep Pro until"
    assert users(:two).reload.pro?
  end

  test "settings offers yearly in rupees, including GST" do
    sign_in_through_ui users(:two)
    visit settings_path(currency: "inr")

    within("#plan") do
      assert_text "₹1,499"
      assert_text "incl. GST, save 37%"
      click_on "Upgrade yearly"
    end
    click_on "Pay ₹1,499 (test)"

    assert_selector "h1", text: "You’re on Pro"
    assert_equal "year", users(:two).current_subscription.interval
  end
end
