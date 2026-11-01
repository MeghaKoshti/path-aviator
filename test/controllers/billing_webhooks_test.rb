require "test_helper"

# POST /webhooks/billing/:provider with recorded Dodo payloads signed by a test secret.
class BillingWebhooksTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
    @previous_secret = ENV["DODO_WEBHOOK_SECRET"]
    ENV["DODO_WEBHOOK_SECRET"] = DODO_TEST_SECRET
  end

  teardown do
    ENV["DODO_WEBHOOK_SECRET"] = @previous_secret
  end

  def deliver(fixture, **options)
    headers, body = dodo_webhook(fixture, user: @user, **options)
    post billing_webhook_path("dodo"), params: body, headers: headers.merge("Content-Type" => "application/json")
  end

  test "a valid subscription.active webhook makes the user Pro" do
    assert_difference [ "Subscription.count", "WebhookEvent.count" ], 1 do
      deliver "subscription_active", id: "msg_1"
    end

    assert_response :ok
    assert @user.reload.pro?
    subscription = @user.current_subscription
    assert_equal [ "dodo", "sub_2IjvDkPvRcbTQkDB5Lc6s", "cus_9pRqLJt5mC2wHn8Yx4bKa", "active" ],
                 [ subscription.provider, subscription.external_id, subscription.customer_id, subscription.status ]
    event = WebhookEvent.sole
    assert_equal [ "dodo", "msg_1", "subscription.active" ], [ event.provider, event.event_id, event.event_type ]
    assert event.processed_at
  end

  test "needs no session or CSRF token and works without a browser user agent" do
    headers, body = dodo_webhook("subscription_active", user: @user)
    post billing_webhook_path("dodo"), params: body, headers: headers.merge("Content-Type" => "application/json", "User-Agent" => "Svix-Webhooks/1.0")

    assert_response :ok
  end

  test "a bad signature is rejected and changes nothing" do
    assert_no_difference [ "Subscription.count", "WebhookEvent.count" ] do
      deliver "subscription_active", secret: "whsec_#{Base64.strict_encode64("forged")}"
    end

    assert_response :unauthorized
    assert @user.reload.free?
  end

  test "a request signed more than five minutes ago is rejected" do
    deliver "subscription_active", timestamp: 6.minutes.ago.to_i

    assert_response :unauthorized
    assert_equal 0, WebhookEvent.count
  end

  test "a duplicate delivery returns 200 and isn't applied twice" do
    deliver "subscription_active", id: "msg_dup"
    @user.current_subscription.update!(status: "canceled", current_period_end: 1.day.ago)
    @user.reload.sync_plan!

    assert_no_difference "WebhookEvent.count" do
      deliver "subscription_active", id: "msg_dup"
    end

    assert_response :ok
    assert @user.current_subscription.canceled?
    assert @user.reload.free?
  end

  test "events we don't act on are recorded and acknowledged" do
    assert_difference "WebhookEvent.count", 1 do
      deliver "payment_succeeded"
    end

    assert_response :ok
    assert_nil WebhookEvent.sole.processed_at
    assert_equal 0, Subscription.count
  end

  test "the full lifecycle: active, payment failed, renewed, cancelled, expired" do
    # The recorded payloads are from 24 October 2026.
    travel_to Time.utc(2026, 10, 24, 10, 20)
    deliver "subscription_active"
    deliver "subscription_on_hold"
    assert @user.current_subscription.past_due?
    assert @user.reload.pro?

    deliver "subscription_renewed"
    assert @user.current_subscription.active?

    deliver "subscription_cancelled"
    assert @user.current_subscription.canceled?
    assert @user.reload.pro?, "keeps Pro until the paid period ends"

    deliver "subscription_expired"
    assert @user.current_subscription.expired?
    assert @user.reload.free?
  end

  test "an unknown provider is not found" do
    post billing_webhook_path("paypal"), params: "{}"

    assert_response :not_found
  end

  test "a webhook for a user we don't know is acknowledged and ignored" do
    @user.destroy!
    deliver "subscription_active"

    assert_response :ok
    assert_equal 0, Subscription.count
  end
end
