# "Manage or cancel": the provider's customer portal for the latest subscription.
class Billing::PortalsController < ApplicationController
  def create
    subscription = Current.user.current_subscription
    return redirect_to settings_path(anchor: "plan"), alert: "You don’t have a subscription to manage." unless subscription

    url = Billing.provider(subscription.provider).portal_url(subscription)
    return redirect_to settings_path(anchor: "plan"), alert: "Cancel from this page; your card is managed by email." unless url

    redirect_to url, allow_other_host: true, status: :see_other
  rescue Billing::Error => e
    Rails.logger.error("[Billing] portal failed for user #{Current.user.id}: #{e.class}: #{e.message}")
    redirect_to settings_path(anchor: "plan"), alert: "We couldn’t open billing management. Please try again in a minute."
  end
end
