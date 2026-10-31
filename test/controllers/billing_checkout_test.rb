require "test_helper"
require "minitest/mock"

class BillingCheckoutTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
    sign_in_as @user
  end

  def fake_checkout_token
    response.location[%r{/billing/fake/checkout/(.+)\z}, 1]
  end

  test "Upgrade sends the user to the provider's checkout for the chosen price" do
    post billing_checkout_path(interval: "year", currency: "usd")

    assert_response :see_other
    assert_match %r{\Ahttp://www.example.com/billing/fake/checkout/.+}, response.location
    assert_equal({ user_id: @user.id, plan: "pro", interval: "year", currency: "usd" }, Billing::FakeProvider.new.read_checkout(fake_checkout_token))
  end

  test "currency defaults from the visitor's country and unknown values fall back" do
    post billing_checkout_path(interval: "weekly", currency: "eur"), headers: { "CF-IPCountry" => "IN" }

    assert_equal({ interval: "month", currency: "inr" }, Billing::FakeProvider.new.read_checkout(fake_checkout_token).slice(:interval, :currency))
  end

  test "paying on the fake checkout makes the user Pro and lands on the welcome page" do
    post billing_checkout_path(interval: "month", currency: "inr")
    token = fake_checkout_token

    get billing_fake_checkout_path(token)
    assert_select "button", "Pay ₹199 (test)"
    assert_select "dd", /incl. GST/

    assert_difference "Subscription.count", 1 do
      post billing_fake_checkout_path(token)
    end
    assert_redirected_to billing_return_path
    assert @user.reload.pro?
    subscription = @user.current_subscription
    assert_equal [ "fake", "month", "inr", "active" ], [ subscription.provider, subscription.interval, subscription.currency, subscription.status ]
    assert_in_delta 1.month.from_now, subscription.current_period_end, 5.seconds

    follow_redirect!
    assert_select "h1", "You’re on Pro"
  end

  test "someone else's or an expired checkout can't be paid" do
    token = Billing::FakeProvider.new.create_checkout(user: users(:one), plan: Plan.pro, interval: "month", currency: "inr").url.split("/").last

    post billing_fake_checkout_path(token)

    assert_redirected_to settings_path(anchor: "plan")
    assert_not @user.reload.pro?
  end

  test "the return page waits for the webhook when the plan hasn't changed yet" do
    get billing_return_path

    assert_select "h1", "Confirming your payment…"
    assert_select "meta[http-equiv=refresh][content='3']"
  end

  test "the demo account and Pro users aren't sent to checkout" do
    @user.update!(plan: :pro)
    post billing_checkout_path
    assert_redirected_to settings_path(anchor: "plan")
    assert_equal "You’re already on Pro.", flash[:notice]

    demo = DemoAccount.reset!
    sign_in_as demo, password: DemoAccount::PASSWORD
    post billing_checkout_path
    assert_match "demo account can’t buy Pro", flash[:alert]
  end

  test "a provider failure brings the user back with a message" do
    failing = Object.new
    def failing.create_checkout(**) = raise(Billing::RequestFailed, "boom")

    Billing.stub(:provider, failing) do
      post billing_checkout_path
    end

    assert_redirected_to settings_path(anchor: "plan")
    assert_match "couldn’t open the checkout", flash[:alert]
  end

  test "checkout needs a session" do
    delete session_path
    post billing_checkout_path

    assert_redirected_to new_session_path
  end

  test "Manage opens the provider's portal, and cancelling there keeps Pro until the period ends" do
    Billing::FakeProvider.new.deliver("activated", user: @user, subscription_id: "fake_sub_1", interval: "month", currency: "inr", current_period_end: 20.days.from_now)

    post billing_portal_path
    assert_redirected_to billing_fake_portal_path

    post billing_fake_portal_cancel_path
    assert_redirected_to settings_path(anchor: "plan")
    assert @user.current_subscription.cancel_at_period_end?
    assert @user.reload.pro?
  end

  test "Manage without a subscription explains there's nothing to manage" do
    post billing_portal_path

    assert_match "don’t have a subscription", flash[:alert]
  end
end
