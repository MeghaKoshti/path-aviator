# "Cancel subscription" for providers without a hosted portal (Razorpay).
# Renewal stops at the end of the paid cycle; the provider's webhook confirms it.
class Billing::CancellationsController < ApplicationController
  def create
    subscription = Current.user.current_subscription
    unless subscription&.cancel_in_app? && (subscription.active? || subscription.past_due?)
      return redirect_to settings_path(anchor: "plan"), alert: "There’s no subscription to cancel here."
    end

    Billing.provider(subscription.provider).cancel(subscription)
    subscription.update!(cancel_at_period_end: true)
    redirect_to settings_path(anchor: "plan"), notice: "Subscription cancelled. You keep Pro until the end of this period.", status: :see_other
  rescue Billing::Error => e
    Rails.logger.error("[Billing] cancel failed for user #{Current.user.id}: #{e.class}: #{e.message}")
    redirect_to settings_path(anchor: "plan"), alert: "We couldn’t cancel right now. Please try again in a minute."
  end
end
