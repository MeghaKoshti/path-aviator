require "test_helper"

class Billing::FakeProviderTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
    @provider = Billing::FakeProvider.new
  end

  test "checkout is a signed local page that remembers the choice" do
    checkout = @provider.create_checkout(user: @user, plan: Plan.pro, interval: "year", currency: "usd")
    token = checkout.url[%r{\A/billing/fake/checkout/(.+)\z}, 1]

    assert_equal({ user_id: @user.id, plan: "pro", interval: "year", currency: "usd" }, @provider.read_checkout(token))
    assert_nil @provider.read_checkout("#{token}x")
  end

  test "checkout links expire after an hour" do
    token = @provider.create_checkout(user: @user, plan: Plan.pro, interval: "month", currency: "inr").url.split("/").last

    travel 61.minutes do
      assert_nil @provider.read_checkout(token)
    end
  end

  test "delivering an activation makes the user Pro through a signed webhook" do
    result = @provider.deliver("activated", user: @user, subscription_id: "fake_sub_1", interval: "month",
                               currency: "inr", current_period_end: 1.month.from_now)
    subscription = result.subscription

    assert subscription.active?
    assert_equal [ "fake", "fake_sub_1", "fake_cus_#{@user.id}" ], [ subscription.provider, subscription.external_id, subscription.customer_id ]
    assert @user.reload.pro?
    assert_equal({ "provider" => "fake", "interval" => "month", "currency" => "inr" }, Event.named(:upgraded).sole.properties)
  end

  test "only a new subscription counts as an upgrade" do
    @provider.deliver("activated", user: @user, subscription_id: "fake_sub_1", interval: "month", currency: "inr", current_period_end: 1.month.from_now)
    @provider.deliver("renewed", user: @user, subscription_id: "fake_sub_1", interval: "month", currency: "inr", current_period_end: 2.months.from_now)

    assert_equal 1, Event.named(:upgraded).count
  end

  test "webhooks signed with another secret are rejected" do
    body = { type: "activated", timestamp: Time.current.iso8601, data: { subscription_id: "x" } }.to_json
    headers = Billing::StandardWebhooks.headers_for(secret: "whsec_#{Base64.strict_encode64("other")}", id: "evt_1", body: body)

    assert_raises(Billing::SignatureError) { @provider.verify_webhook(headers, body) }
  end

  test "the portal is a local page" do
    assert_equal "/billing/fake/portal", @provider.portal_url(nil)
  end
end
