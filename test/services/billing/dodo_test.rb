require "test_helper"

class Billing::DodoTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
  end

  test "creates a checkout session for the product of the chosen price" do
    http = FakeHttp.new([ 200, file_fixture("dodo/checkout_response.json").read ])

    checkout = dodo_provider(http: http).create_checkout(user: @user, plan: Plan.pro, interval: "month", currency: "inr")

    assert_equal "https://test.checkout.dodopayments.com/session/cks_0NVuQKk2iMVo7gEEoeLvN", checkout.url
    request = http.requests.sole
    assert_equal "https://test.dodopayments.com/checkouts", request[:url]
    assert_equal "Bearer test_api_key", request[:headers]["Authorization"]
    expected = JSON.parse(file_fixture("dodo/checkout_request.json").read.gsub("USER_ID", @user.id.to_s))
    assert_equal expected, request[:body]
  end

  test "picks the product id for each interval and currency" do
    http = FakeHttp.new([ 200, file_fixture("dodo/checkout_response.json").read ])

    dodo_provider(http: http).create_checkout(user: @user, plan: Plan.pro, interval: "year", currency: "usd")

    assert_equal "pdt_pro_yearly_usd", http.requests.sole.dig(:body, "product_cart", 0, "product_id")
  end

  test "a returning customer checks out as the same Dodo customer" do
    @user.subscriptions.create!(provider: "dodo", external_id: "sub_old", customer_id: "cus_known", interval: "month", currency: "inr", status: "canceled")
    http = FakeHttp.new([ 200, file_fixture("dodo/checkout_response.json").read ])

    dodo_provider(http: http).create_checkout(user: @user, plan: Plan.pro, interval: "month", currency: "inr")

    assert_equal({ "customer_id" => "cus_known" }, http.requests.sole.dig(:body, "customer"))
  end

  test "live mode talks to the live host" do
    http = FakeHttp.new([ 200, file_fixture("dodo/checkout_response.json").read ])

    dodo_provider(http: http, environment: "live_mode").create_checkout(user: @user, plan: Plan.pro, interval: "month", currency: "inr")

    assert_equal "https://live.dodopayments.com/checkouts", http.requests.sole[:url]
  end

  test "an API error or an unexpected answer raises a billing error" do
    assert_raises(Billing::RequestFailed) do
      dodo_provider(http: FakeHttp.new([ 401, '{"message":"Unauthorized"}' ])).create_checkout(user: @user, plan: Plan.pro, interval: "month", currency: "inr")
    end
    assert_raises(Billing::RequestFailed) do
      dodo_provider(http: FakeHttp.new([ 200, "{}" ])).create_checkout(user: @user, plan: Plan.pro, interval: "month", currency: "inr")
    end
  end

  test "a missing product id is a configuration error" do
    provider = dodo_provider(product_ids: BillingTestHelper::DODO_PRODUCT_IDS.merge([ "year", "usd" ] => nil))

    assert_not provider.configured?
    assert_raises(Billing::NotConfigured) { provider.create_checkout(user: @user, plan: Plan.pro, interval: "year", currency: "usd") }
  end

  test "is configured only with a key, a webhook secret and every product id" do
    assert dodo_provider.configured?
    assert_not dodo_provider(api_key: nil).configured?
    assert_not dodo_provider(webhook_secret: "").configured?
  end

  test "reads product ids from DODO_PRODUCT_PRO_* variables" do
    with_env("DODO_PRODUCT_PRO_MONTHLY_INR" => "pdt_a", "DODO_PRODUCT_PRO_YEARLY_USD" => "pdt_b") do
      ids = Billing::Dodo.product_ids_from_env

      assert_equal "pdt_a", ids[[ "month", "inr" ]]
      assert_equal "pdt_b", ids[[ "year", "usd" ]]
    end
  end

  test "opens a customer portal session for the subscription's customer" do
    subscription = @user.subscriptions.create!(provider: "dodo", external_id: "sub_1", customer_id: "cus_9pRq", interval: "month", currency: "inr", status: "active")
    http = FakeHttp.new([ 200, file_fixture("dodo/portal_response.json").read ])

    url = dodo_provider(http: http).portal_url(subscription)

    assert_equal "https://test.customer.dodopayments.com/session/cps_8KMb7PYkzv3QbBYyj2FtG", url
    request_url = URI(http.requests.sole[:url])
    assert_equal "/customers/cus_9pRq/customer-portal/session", request_url.path
    assert_equal "http://example.com/settings#plan", Rack::Utils.parse_query(request_url.query)["return_url"]
  end

  test "turns a signed subscription.active webhook into an activation event" do
    headers, body = dodo_webhook("subscription_active", user: @user, id: "msg_abc")

    event = dodo_provider.verify_webhook(headers, body)

    assert_equal "msg_abc", event.id
    assert_equal "activated", event.type
    assert_equal Time.utc(2026, 10, 24, 10, 15, 2.418r), event.occurred_at
    info = event.subscription
    assert_equal [ "sub_2IjvDkPvRcbTQkDB5Lc6s", "cus_9pRqLJt5mC2wHn8Yx4bKa", @user.id.to_s, "two@example.com" ],
                 [ info.external_id, info.customer_id, info.user_id, info.email ]
    assert_equal [ "month", "inr", false ], [ info.interval, info.currency, info.cancel_at_period_end ]
    assert_equal Time.utc(2026, 11, 24, 10, 14, 51.902r), info.current_period_end
  end

  test "maps Dodo's event names to ours" do
    {
      "subscription_renewed" => "renewed", "subscription_on_hold" => "payment_failed",
      "subscription_cancelled" => "canceled", "subscription_expired" => "expired", "payment_succeeded" => nil
    }.each do |fixture, type|
      headers, body = dodo_webhook(fixture, user: @user)
      actual = dodo_provider.verify_webhook(headers, body).type
      type ? assert_equal(type, actual, fixture) : assert_nil(actual, fixture)
    end
  end

  test "a cancellation keeps the paid-up period end" do
    headers, body = dodo_webhook("subscription_cancelled", user: @user)

    info = dodo_provider.verify_webhook(headers, body).subscription

    assert info.cancel_at_period_end
    assert_equal Time.utc(2026, 11, 24, 10, 14, 51.902r), info.current_period_end
  end

  test "rejects webhooks with a bad signature or an old timestamp" do
    headers, body = dodo_webhook("subscription_active", user: @user, secret: "whsec_#{Base64.strict_encode64("wrong")}")
    assert_raises(Billing::SignatureError) { dodo_provider.verify_webhook(headers, body) }

    headers, body = dodo_webhook("subscription_active", user: @user, timestamp: 10.minutes.ago.to_i)
    assert_raises(Billing::SignatureError) { dodo_provider.verify_webhook(headers, body) }
  end
end
