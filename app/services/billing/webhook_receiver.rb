module Billing
  # Turns a provider's webhook into changes on our side, exactly once:
  # checks the signature, records the event id (a retry of the same event is
  # recognised by the unique index), then moves the Subscription through its
  # states and updates the user's plan.
  #
  #   Billing::WebhookReceiver.call(provider, headers, raw_body)
  #   # => Result(status: :processed | :duplicate | :ignored, subscription:)
  #
  # Raises Billing::SignatureError for unsigned or stale requests.
  class WebhookReceiver
    Result = Data.define(:status, :subscription)

    def self.call(provider, headers, body)
      new(provider).call(headers, body)
    end

    def initialize(provider)
      @provider = provider
    end

    def call(headers, body)
      event = @provider.verify_webhook(headers, body)

      # One transaction: if applying fails, the event isn't recorded either,
      # so the provider's retry gets another go.
      WebhookEvent.transaction do
        record = WebhookEvent.create!(provider: @provider.name, event_id: event.id, event_type: event.raw["type"] || event.raw["event"],
                                      payload: body)
        subscription = apply(event)
        record.update!(processed_at: Time.current) if subscription
        Result.new(status: subscription ? :processed : :ignored, subscription: subscription)
      end
    rescue ActiveRecord::RecordNotUnique
      Result.new(status: :duplicate, subscription: nil)
    end

    private
      def apply(event)
        return if event.type.nil? || event.subscription&.external_id.blank?

        subscription = find_or_build_subscription(event)
        return unless subscription

        subscription.apply_event!(event)
        subscription
      end

      def find_or_build_subscription(event)
        info = event.subscription
        existing = Subscription.lock.find_by(provider: @provider.name, external_id: info.external_id)
        return existing if existing

        # Only an activation (or renewal) starts our copy; anything else about
        # a subscription we've never seen has nothing to act on.
        return unless event.type.in?(%w[activated renewed])

        user = find_user(info)
        if user.nil? || info.interval.blank? || info.currency.blank?
          Rails.logger.warn("[Billing] #{@provider.name} subscription #{info.external_id} matches no user or lacks details; skipped")
          return
        end

        user.subscriptions.new(provider: @provider.name, external_id: info.external_id)
      end

      # We put our user id in the checkout's metadata; the email is the fallback
      # for a subscription started some other way.
      def find_user(info)
        User.find_by(id: info.user_id) || (info.email.present? && User.find_by(email_address: info.email.to_s.strip.downcase))
      end
  end
end
