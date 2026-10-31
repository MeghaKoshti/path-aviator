require "test_helper"
require "minitest/mock"

# Razorpay end to end: webhooks through /webhooks/billing/razorpay, and
# cancelling from settings since Razorpay has no customer portal.
class RazorpayBillingTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
    @previous_secret = ENV["RAZORPAY_WEBHOOK_SECRET"]
    ENV["RAZORPAY_WEBHOOK_SECRET"] = RAZORPAY_TEST_SECRET
  end

  teardown do
    ENV["RAZORPAY_WEBHOOK_SECRET"] = @previous_secret
  end

  def deliver(fixture, **options)
    headers, body = razorpay_webhook(fixture, user: @user, **options)
    post billing_webhook_path("razorpay"), params: body, headers: headers.merge("Content-Type" => "application/json")
  end

  test "activation, a failed charge, a renewal and cancellation move the plan" do
    travel_to Time.zone.at(1793357000) do
      deliver "subscription_activated", id: "evt_1"
      assert_response :ok
      assert @user.reload.pro?
      assert_equal "razorpay", @user.current_subscription.provider

      deliver "subscription_activated", id: "evt_1"
      assert_response :ok
      assert_equal 1, WebhookEvent.count
    end

    travel_to Time.zone.at(1795949600) do
      deliver "subscription_pending"
      assert @user.current_subscription.past_due?
      deliver "subscription_charged"
      assert @user.current_subscription.active?
      assert @user.reload.pro?
    end

    travel_to Time.zone.at(1796300100) do
      deliver "subscription_halted"
      assert @user.current_subscription.expired?
      assert @user.reload.free?
    end
  end

  test "a bad signature is rejected" do
    deliver "subscription_activated", secret: "forged"

    assert_response :unauthorized
    assert_equal 0, Subscription.count
  end

  test "subscribers cancel from settings, keeping Pro until the cycle ends" do
    subscription = @user.subscriptions.create!(provider: "razorpay", external_id: "sub_1", interval: "month", currency: "inr",
                                               status: "active", current_period_end: 20.days.from_now)
    @user.sync_plan!
    sign_in_as @user

    get settings_path
    assert_select "form[action=?] button", billing_cancellation_path, text: "Cancel subscription"
    assert_select "form[action=?]", billing_portal_path, count: 0

    provider = razorpay_provider(http: FakeHttp.new([ 200, "{}" ]))
    Billing.stub(:provider, provider) { post billing_cancellation_path }

    assert_redirected_to settings_path(anchor: "plan")
    assert subscription.reload.cancel_at_period_end?
    assert @user.reload.pro?
    assert_match "/subscriptions/sub_1/cancel", provider.instance_variable_get(:@http).requests.sole[:url]
  end

  test "rupees can go to Razorpay while dollars stay with another provider" do
    with_env("BILLING_PROVIDER_INR" => "razorpay", "BILLING_PROVIDER" => "fake") do
      assert_instance_of Billing::Razorpay, Billing.provider_for("inr")
      assert_instance_of Billing::FakeProvider, Billing.provider_for("usd")
    end
  end
end
