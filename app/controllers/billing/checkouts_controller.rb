# "Upgrade to Pro": starts a hosted checkout at the payment provider.
class Billing::CheckoutsController < ApplicationController
  rate_limit to: 10, within: 10.minutes, only: :create, by: -> { Current.user.id },
    with: -> { redirect_to settings_path(anchor: "plan"), alert: "Too many checkout attempts. Try again in a few minutes." }

  def create
    if Current.user.demo?
      redirect_to settings_path(anchor: "plan"), alert: "The demo account can’t buy Pro. Sign up to upgrade."
    elsif Current.user.pro?
      redirect_to settings_path(anchor: "plan"), notice: "You’re already on Pro."
    else
      checkout = Billing.provider.create_checkout(user: Current.user, plan: Plan.pro, interval: interval, currency: currency)
      redirect_to checkout.url, allow_other_host: true, status: :see_other
    end
  rescue Billing::Error => e
    Rails.logger.error("[Billing] checkout failed for user #{Current.user.id}: #{e.class}: #{e.message}")
    redirect_to settings_path(anchor: "plan"), alert: "We couldn’t open the checkout. Please try again in a minute."
  end

  private
    def interval
      params[:interval].presence_in(Billing::INTERVALS) || "month"
    end

    def currency
      params[:currency].presence_in(Billing::CURRENCIES) || cookies[:currency].presence_in(Billing::CURRENCIES) ||
        Billing.currency_for(request)
    end
end
