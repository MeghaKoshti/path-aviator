# Our copy of a paid subscription at the payment provider. Webhooks update it
# (Billing::WebhookReceiver) and it keeps users.plan in step.
class Subscription < ApplicationRecord
  belongs_to :user

  enum :status, { trialing: "trialing", active: "active", past_due: "past_due", canceled: "canceled" }, validate: true

  validates :provider, :external_id, presence: true
  validates :interval, inclusion: { in: Billing::INTERVALS }
  validates :currency, inclusion: { in: Billing::CURRENCIES }

  scope :latest_first, -> { order(created_at: :desc, id: :desc) }

  # Does this subscription entitle the user to Pro right now?
  def grants_pro?(now: Time.current)
    active? || trialing?
  end

  def plan_details
    Plan.find(plan)
  end

  # Applies a Billing::Event from the provider.
  def apply_event!(event)
    copy_details(event.subscription)
    upgrading = new_record? && event.type.in?(%w[activated renewed])
    self.status = :active if event.type.in?(%w[activated renewed])
    save!
    user.sync_plan!
    Event.track(:upgraded, user: user, provider: provider, interval: interval, currency: currency) if upgrading
  end

  private
    def copy_details(info)
      self.customer_id = info.customer_id if info.customer_id.present?
      self.interval = info.interval if info.interval.present?
      self.currency = info.currency if info.currency.present?
      self.current_period_end = info.current_period_end if info.current_period_end
      self.cancel_at_period_end = info.cancel_at_period_end
    end
end
