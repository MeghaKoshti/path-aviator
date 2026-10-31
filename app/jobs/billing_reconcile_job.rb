# Daily safety net for missed webhooks (config/recurring.yml): cancelled
# subscriptions whose paid period is over become expired, past-due ones lose
# Pro once the grace period ends, and every affected user's plan is re-synced.
class BillingReconcileJob < ApplicationJob
  queue_as :default

  def perform(now: Time.current)
    changed = 0
    Subscription.where(status: %w[past_due canceled]).includes(:user).find_each do |subscription|
      changed += 1 if subscription.reconcile!(now: now)
    end

    # An active subscription long past its period end means a renewal webhook
    # never arrived. Flag it for a human rather than guess either way.
    Subscription.active.where(current_period_end: ...(now - Subscription::PAST_DUE_GRACE)).find_each do |subscription|
      Rails.logger.warn("[Billing] #{subscription.provider} subscription #{subscription.external_id} is active but its period ended #{subscription.current_period_end}; check the provider")
    end

    Rails.logger.info("[Billing] reconcile changed #{changed} subscription(s)")
  end
end
