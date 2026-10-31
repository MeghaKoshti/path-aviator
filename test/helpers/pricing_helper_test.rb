require "test_helper"

class PricingHelperTest < ActionView::TestCase
  test "formats paise and cents without decimals when whole" do
    assert_equal "₹199", format_price(19900, :inr)
    assert_equal "₹1,499", format_price(149900, :inr)
    assert_equal "$6", format_price(600, :usd)
    assert_equal "$6.50", format_price(650, :usd)
  end

  test "prices, monthly equivalent and savings come from the plan" do
    assert_equal "₹199", plan_price(Plan.pro, currency: :inr, interval: :month)
    assert_equal "$48", plan_price(Plan.pro, currency: :usd, interval: :year)
    assert_equal "₹125", yearly_price_per_month(Plan.pro, currency: :inr)
    assert_equal "$4", yearly_price_per_month(Plan.pro, currency: :usd)
    assert_equal 37, yearly_savings_percent(Plan.pro, currency: :inr)
    assert_equal 33, yearly_savings_percent(Plan.pro, currency: :usd)
  end

  test "pro_user? works before and after users get a plan" do
    assert_not pro_user?(Object.new)
    assert pro_user?(Struct.new(:pro?).new(true))
  end
end
