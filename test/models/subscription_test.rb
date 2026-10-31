require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
    @now = Time.utc(2026, 10, 24, 12)
    @period_end = @now + 1.month
    @subscription = @user.subscriptions.new(provider: "fake", external_id: "fake_sub_1")
  end

  def event(type, at: @now, period_end: @period_end, cancel: false)
    info = Billing::SubscriptionInfo.new(external_id: "fake_sub_1", customer_id: "fake_cus", user_id: @user.id, email: nil,
                                         interval: "month", currency: "inr", current_period_end: period_end, cancel_at_period_end: cancel)
    Billing::Event.new(id: SecureRandom.hex, type: type, occurred_at: at, subscription: info, raw: {})
  end

  def apply(type, **options)
    travel_to(options[:at] || @now) { @subscription.apply_event!(event(type, **options)) }
  end

  test "activation makes the user Pro" do
    apply "activated"

    assert @subscription.active?
    assert_equal @period_end, @subscription.current_period_end
    assert @user.reload.pro?
  end

  test "a renewal moves the period on and clears a failed payment" do
    apply "activated"
    apply "payment_failed", at: @now + 1.month
    apply "renewed", at: @now + 1.month + 1.day, period_end: @now + 2.months

    assert @subscription.active?
    assert_nil @subscription.past_due_at
    assert_equal @now + 2.months, @subscription.current_period_end
    assert @user.reload.pro?
  end

  test "a failed payment keeps Pro for three days, then ends it" do
    apply "activated"
    failed_at = @now + 1.month
    apply "payment_failed", at: failed_at

    assert @subscription.past_due?
    assert @subscription.grants_pro?(now: failed_at + 3.days - 1.minute)
    assert_not @subscription.grants_pro?(now: failed_at + 3.days)
    assert @user.reload.pro?
  end

  test "repeated payment failures don't extend the grace period" do
    apply "activated"
    apply "payment_failed", at: @now + 1.month
    apply "payment_failed", at: @now + 1.month + 2.days

    assert_equal @now + 1.month, @subscription.past_due_at
  end

  test "a cancellation keeps Pro until the paid period ends" do
    apply "activated"
    apply "canceled", at: @now + 5.days, cancel: true

    assert @subscription.canceled?
    assert @subscription.cancel_at_period_end?
    assert @subscription.grants_pro?(now: @period_end - 1.minute)
    assert_not @subscription.grants_pro?(now: @period_end)
    assert @user.reload.pro?
  end

  test "expiry moves the user back to Free" do
    apply "activated"
    apply "expired", at: @period_end

    assert @subscription.expired?
    assert_not @subscription.grants_pro?
    assert @user.reload.free?
  end

  test "an update changes details but not the status" do
    apply "activated"
    apply "updated", at: @now + 1.day, cancel: true

    assert @subscription.active?
    assert @subscription.cancel_at_period_end?
  end

  test "an event older than one already applied is skipped" do
    apply "activated"
    apply "expired", at: @now + 1.month
    assert_not apply("renewed", at: @now + 2.days)

    assert @subscription.reload.expired?
    assert @user.reload.free?
  end

  test "Pro stays while any subscription grants it" do
    apply "activated"
    @user.subscriptions.create!(provider: "fake", external_id: "old", interval: "month", currency: "inr", status: "expired")

    @user.sync_plan!

    assert @user.reload.pro?
  end

  test "reconcile expires a cancelled subscription whose period is over" do
    apply "activated"
    apply "canceled", at: @now + 1.day, cancel: true

    assert @subscription.reconcile!(now: @period_end + 1.hour)
    assert @subscription.expired?
    assert @user.reload.free?
    assert_not @subscription.reconcile!(now: @period_end + 2.hours)
  end

  test "only becoming active from nothing or an ended subscription counts as an upgrade" do
    apply "activated"
    apply "payment_failed", at: @now + 1.month
    apply "renewed", at: @now + 1.month + 1.day
    assert_equal 1, Event.named(:upgraded).count

    apply "expired", at: @now + 3.months
    apply "activated", at: @now + 4.months
    assert_equal 2, Event.named(:upgraded).count
  end
end
