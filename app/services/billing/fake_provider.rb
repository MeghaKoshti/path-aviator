module Billing
  # A pretend payment provider for development and tests. Checkout and the
  # customer portal are pages inside the app (Billing::FakeCheckoutsController);
  # "paying" builds a webhook signed exactly like a real one and hands it to
  # Billing::WebhookReceiver, so the same code path as production runs.
  #
  # Never available in production (see Billing.provider).
  class FakeProvider < Provider
    def self.secret
      "whsec_#{Base64.strict_encode64(Rails.application.key_generator.generate_key("billing/fake webhooks", 32))}"
    end

    def initialize(secret: self.class.secret)
      @secret = secret
    end

    def name = "fake"
    def configured? = true

    def create_checkout(user:, plan:, interval:, currency:)
      token = verifier.generate({ "user_id" => user.id, "plan" => plan.key.to_s, "interval" => interval, "currency" => currency },
                                purpose: :fake_checkout, expires_in: 1.hour)
      # A path, not a URL: the fake pages live in this app on whatever host and
      # port it runs (bin/dev, a system test server).
      Checkout.new(url: url_helpers.billing_fake_checkout_path(token))
    end

    # The checkout a token stands for, or nil when it's forged or expired.
    def read_checkout(token)
      verifier.verified(token, purpose: :fake_checkout)&.symbolize_keys
    end

    def portal_url(_subscription)
      url_helpers.billing_fake_portal_path
    end

    def verify_webhook(headers, body)
      StandardWebhooks.verify!(secret: @secret, headers: headers, body: body)
      payload = JSON.parse(body)
      data = payload.fetch("data")

      Event.new(
        id: headers["webhook-id"],
        type: payload["type"].presence_in(EVENT_TYPES),
        occurred_at: Time.zone.parse(payload["timestamp"]),
        subscription: SubscriptionInfo.new(
          external_id: data["subscription_id"],
          customer_id: data["customer_id"],
          user_id: data["user_id"],
          email: data["email"],
          interval: data["interval"],
          currency: data["currency"],
          current_period_end: data["current_period_end"] && Time.zone.parse(data["current_period_end"]),
          cancel_at_period_end: data["cancel_at_period_end"] || false
        ),
        raw: payload
      )
    rescue JSON::ParserError, KeyError
      raise SignatureError, "Malformed fake webhook"
    end

    # Plays the provider's side: sends a signed webhook about a subscription.
    # Returns what Billing::WebhookReceiver returns.
    def deliver(type, user:, subscription_id:, interval:, currency:, current_period_end:, cancel_at_period_end: false)
      body = {
        type: type,
        timestamp: Time.current.iso8601,
        data: {
          subscription_id: subscription_id, customer_id: "fake_cus_#{user.id}", user_id: user.id, email: user.email_address,
          interval: interval, currency: currency, current_period_end: current_period_end.iso8601, cancel_at_period_end: cancel_at_period_end
        }
      }.to_json
      headers = StandardWebhooks.headers_for(secret: @secret, id: "fake_evt_#{SecureRandom.hex(8)}", body: body)

      WebhookReceiver.call(self, headers, body)
    end

    private
      def verifier
        Rails.application.message_verifier("billing/fake checkout")
      end
  end
end
