# Our copy of a paid subscription at the payment provider. Webhooks drive it
# through these states (Billing::WebhookReceiver), and it keeps users.plan in
# step:
#
#   activated / renewed  -> active     Pro
#   payment_failed       -> past_due   Pro for PAST_DUE_GRACE after the first failure
#   canceled             -> canceled   Pro until current_period_end
#   expired              -> expired    Free
#
# BillingReconcileJob re-checks every day in case a webhook was missed.
class Subscription < ApplicationRecord
  PAST_DUE_GRACE = 3.days

  belongs_to :user

  enum :status, { trialing: "trialing", active: "active", past_due: "past_due", canceled: "canceled", expired: "expired" },
       validate: true

  validates :provider, :external_id, presence: true
  validates :interval, inclusion: { in: Billing::INTERVALS }
  validates :currency, inclusion: { in: Billing::CURRENCIES }

  scope :latest_first, -> { order(created_at: :desc, id: :desc) }

  # Does this subscription entitle the user to Pro at this moment?
  def grants_pro?(now: Time.current)
    case status
    when "active", "trialing" then true
    when "past_due" then past_due_at.nil? || now < grace_ends_at
    when "canceled" then current_period_end.present? && now < current_period_end
    else false
    end
  end

  def grace_ends_at
    past_due_at && past_due_at + PAST_DUE_GRACE
  end

  # Cancelled in settings rather than in the provider's portal (Razorpay).
  def cancel_in_app?
    Billing::CANCEL_IN_APP.include?(provider)
  end

  def plan_details
    Plan.find(plan)
  end

  # Applies a Billing::Event from the provider. Returns false (and changes
  # nothing) when the event is older than one already applied.
  def apply_event!(event)
    return false if stale?(event)

    copy_details(event.subscription)
    # A new (or ended) subscription turning active is an upgrade; a renewal
    # or a recovered payment is not.
    upgrading = (new_record? || expired? || canceled?) && event.type.in?(%w[activated renewed])
    transition(event)
    self.last_event_at = event.occurred_at if event.occurred_at
    save!
    user.sync_plan!
    Event.track(:upgraded, user: user, provider: provider, interval: interval, currency: currency) if upgrading
    true
  end

  # The daily safety net for missed webhooks: a cancelled subscription whose
  # paid period is over becomes expired. Returns true when something changed.
  def reconcile!(now: Time.current)
    expire = canceled? && current_period_end.present? && current_period_end <= now
    update!(status: :expired) if expire

    plan_before = user.plan
    user.sync_plan!
    expire || user.plan != plan_before
  end

  private
    def stale?(event)
      persisted? && last_event_at && event.occurred_at && event.occurred_at < last_event_at
    end

    def transition(event)
      case event.type
      when "activated", "renewed"
        self.status = :active
        self.past_due_at = nil
      when "payment_failed"
        self.status = :past_due
        self.past_due_at ||= event.occurred_at || Time.current
      when "canceled"
        self.status = :canceled
        self.cancel_at_period_end = true
      when "expired"
        self.status = :expired
      end
      # "updated" changes details only (dates, cancel flag); status changes
      # come with their own events.
    end

    def copy_details(info)
      self.customer_id = info.customer_id if info.customer_id.present?
      self.interval = info.interval if info.interval.present?
      self.currency = info.currency if info.currency.present?
      self.current_period_end = info.current_period_end if info.current_period_end
      self.cancel_at_period_end = info.cancel_at_period_end unless info.cancel_at_period_end.nil?
    end
end
