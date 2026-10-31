require "test_helper"

class Billing::RazorpayTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
  end

  def response_fixture
    file_fixture("razorpay/subscription_create_response.json").read.gsub("USER_ID", @user.id.to_s)
  end

  test "creates a subscription for the price's plan and returns its hosted link" do
    http = FakeHttp.new([ 200, response_fixture ])

    checkout = razorpay_provider(http: http).create_checkout(user: @user, plan: Plan.pro, interval: "month", currency: "inr")

    assert_equal "https://rzp.io/rzp/Dqdqx3h", checkout.url
    request = http.requests.sole
    assert_equal "https://api.razorpay.com/v1/subscriptions", request[:url]
    assert_equal "Basic #{Base64.strict_encode64("rzp_test_key:rzp_test_secret")}", request[:headers]["Authorization"]
    assert_equal({ "plan_id" => "plan_pro_monthly_inr", "total_count" => 120, "quantity" => 1, "customer_notify" => true,
                   "notes" => { "user_id" => @user.id.to_s, "email" => "two@example.com", "interval" => "month", "currency" => "inr" } },
                 request[:body])
  end

  test "yearly plans run for ten cycles" do
    http = FakeHttp.new([ 200, response_fixture ])

    razorpay_provider(http: http).create_checkout(user: @user, plan: Plan.pro, interval: "year", currency: "inr")

    assert_equal [ "plan_pro_yearly_inr", 10 ], http.requests.sole[:body].values_at("plan_id", "total_count")
  end

  test "is configured with keys, a webhook secret and the INR plans; USD plans are optional" do
    assert razorpay_provider.configured?
    assert_not razorpay_provider(key_secret: nil).configured?
    assert_not razorpay_provider(plan_ids: RAZORPAY_PLAN_IDS.merge([ "year", "inr" ] => nil)).configured?
    assert_raises(Billing::NotConfigured) { razorpay_provider.create_checkout(user: @user, plan: Plan.pro, interval: "month", currency: "usd") }
  end

  test "reads plan ids from RAZORPAY_PLAN_PRO_* variables" do
    with_env("RAZORPAY_PLAN_PRO_YEARLY_INR" => "plan_x") do
      assert_equal "plan_x", Billing::Razorpay.plan_ids_from_env[[ "year", "inr" ]]
    end
  end

  test "API errors raise a billing error" do
    assert_raises(Billing::RequestFailed) do
      razorpay_provider(http: FakeHttp.new([ 400, '{"error":{"code":"BAD_REQUEST_ERROR"}}' ])).create_checkout(user: @user, plan: Plan.pro, interval: "month", currency: "inr")
    end
  end

  test "cancels at the end of the paid cycle" do
    http = FakeHttp.new([ 200, "{}" ])
    subscription = Subscription.new(external_id: "sub_00000000000001")

    razorpay_provider(http: http).cancel(subscription)

    assert_equal "https://api.razorpay.com/v1/subscriptions/sub_00000000000001/cancel", http.requests.sole[:url]
    assert_equal({ "cancel_at_cycle_end" => true }, http.requests.sole[:body])
  end

  test "has no hosted portal" do
    assert_nil razorpay_provider.portal_url(nil)
  end

  test "turns a signed subscription.activated webhook into an activation event" do
    headers, body = razorpay_webhook("subscription_activated", user: @user, id: "evt_1")

    event = razorpay_provider.verify_webhook(headers, body)

    assert_equal [ "evt_1", "activated" ], [ event.id, event.type ]
    assert_equal Time.zone.at(1793356900), event.occurred_at
    info = event.subscription
    assert_equal [ "sub_00000000000001", "cust_4xbQrmEoA5WJ0G", @user.id.to_s, "two@example.com", "month", "inr" ],
                 [ info.external_id, info.customer_id, info.user_id, info.email, info.interval, info.currency ]
    assert_equal Time.zone.at(1795948800), info.current_period_end
  end

  test "maps Razorpay's event names to ours" do
    {
      "subscription_charged" => "renewed", "subscription_pending" => "payment_failed", "subscription_halted" => "expired",
      "subscription_cancelled" => "canceled", "subscription_authenticated" => nil
    }.each do |fixture, type|
      headers, body = razorpay_webhook(fixture, user: @user)
      actual = razorpay_provider.verify_webhook(headers, body).type
      type ? assert_equal(type, actual, fixture) : assert_nil(actual, fixture)
    end
  end

  test "rejects a missing or wrong signature" do
    headers, body = razorpay_webhook("subscription_activated", user: @user, secret: "someone-else")
    assert_raises(Billing::SignatureError) { razorpay_provider.verify_webhook(headers, body) }

    assert_raises(Billing::SignatureError) { razorpay_provider.verify_webhook({}, body) }
    headers, body = razorpay_webhook("subscription_activated", user: @user)
    assert_raises(Billing::SignatureError) { razorpay_provider.verify_webhook(headers, body.sub("month", "year")) }
  end
end
