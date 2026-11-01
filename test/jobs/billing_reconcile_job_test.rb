require "test_helper"

class BillingReconcileJobTest < ActiveJob::TestCase
  def subscription_for(user, **attributes)
    user.subscriptions.create!({ provider: "fake", external_id: "fake_sub_#{user.id}", interval: "month", currency: "inr" }.merge(attributes))
  end

  test "downgrades users whose cancelled period ended or whose grace ran out, and leaves the rest" do
    now = Time.current
    cancelled = subscription_for(users(:one), status: "canceled", current_period_end: now - 1.hour)
    unpaid = subscription_for(users(:two), status: "past_due", past_due_at: now - 4.days, current_period_end: now - 4.days)
    still_paid = subscription_for(users(:unverified), status: "canceled", current_period_end: now + 1.week)
    [ users(:one), users(:two), users(:unverified) ].each { |user| user.update!(plan: :pro) }

    BillingReconcileJob.perform_now

    assert cancelled.reload.expired?
    assert users(:one).reload.free?
    assert unpaid.reload.past_due?
    assert users(:two).reload.free?
    assert still_paid.reload.canceled?
    assert users(:unverified).reload.pro?
  end

  test "flags an active subscription whose renewal never arrived" do
    subscription_for(users(:one), status: "active", current_period_end: 5.days.ago)
    log = StringIO.new
    original = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(log)

    BillingReconcileJob.perform_now

    assert_match "is active but its period ended", log.string
  ensure
    Rails.logger = original
  end

  test "runs every day in production" do
    schedule = YAML.load_file(Rails.root.join("config/recurring.yml"))

    assert_equal "BillingReconcileJob", schedule.dig("production", "billing_reconcile", "class")
    assert_match(/every day/, schedule.dig("production", "billing_reconcile", "schedule"))
  end
end
