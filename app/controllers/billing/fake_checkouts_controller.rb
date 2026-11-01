# The fake provider's hosted pages: a checkout and a customer portal. They
# exist only outside production so the upgrade flow can be clicked through
# locally and in system tests. Paying sends a signed webhook in-process (a
# server calling itself over HTTP could deadlock with one worker).
class Billing::FakeCheckoutsController < ApplicationController
  before_action :set_checkout, only: %i[ show create ]

  def show
  end

  # "Pay"
  def create
    provider.deliver("activated", user: Current.user, subscription_id: "fake_sub_#{SecureRandom.hex(6)}",
                     interval: @checkout[:interval], currency: @checkout[:currency],
                     current_period_end: 1.public_send(@checkout[:interval]).from_now)
    redirect_to billing_return_path, status: :see_other
  end

  def portal
    @subscription = Current.user.subscriptions.where(provider: "fake").latest_first.first
  end

  # "Cancel subscription" in the fake portal: Pro stays until the period ends.
  def cancel
    subscription = Current.user.subscriptions.where(provider: "fake").latest_first.first!
    provider.deliver("canceled", user: Current.user, subscription_id: subscription.external_id,
                     interval: subscription.interval, currency: subscription.currency,
                     current_period_end: subscription.current_period_end, cancel_at_period_end: true)
    redirect_to settings_path(anchor: "plan"), notice: "Subscription cancelled.", status: :see_other
  end

  private
    def provider
      @provider ||= Billing.provider("fake")
    end

    def set_checkout
      @checkout = provider.read_checkout(params[:token])
      return if @checkout && @checkout[:user_id] == Current.user.id

      redirect_to settings_path(anchor: "plan"), alert: "That checkout has expired. Start again."
    end
end
