module Billing
  # Turns a provider's webhook into changes on our side: checks the
  # signature, then creates or updates the Subscription and the user's plan.
  #
  #   Billing::WebhookReceiver.call(provider, headers, raw_body) # => Subscription or nil
  class WebhookReceiver
    def self.call(provider, headers, body)
      new(provider).call(headers, body)
    end

    def initialize(provider)
      @provider = provider
    end

    def call(headers, body)
      event = @provider.verify_webhook(headers, body)
      return if event.type.nil? || event.subscription&.external_id.blank?

      apply(event)
    end

    private
      def apply(event)
        Subscription.transaction do
          subscription = find_or_build_subscription(event.subscription)
          return unless subscription

          subscription.apply_event!(event)
          subscription
        end
      end

      def find_or_build_subscription(info)
        existing = Subscription.find_by(provider: @provider.name, external_id: info.external_id)
        return existing if existing

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
