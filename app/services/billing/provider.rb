module Billing
  # What every payment provider adapter implements. Adapters only talk to the
  # provider and translate; Billing::WebhookReceiver applies the result.
  class Provider
    # Short name used in URLs (/webhooks/billing/:provider) and the database.
    def name
      raise NotImplementedError
    end

    # false when keys are missing, so Upgrade buttons can be hidden.
    def configured?
      raise NotImplementedError
    end

    # Starts a hosted checkout for the plan and returns a Billing::Checkout
    # whose url the user is sent to. Raises Billing::Error on failure.
    def create_checkout(user:, plan:, interval:, currency:)
      raise NotImplementedError
    end

    # A link where the subscriber can update their card or cancel.
    def portal_url(subscription)
      raise NotImplementedError
    end

    # Checks the signature and returns a Billing::Event, or raises
    # Billing::SignatureError. body is the raw request body.
    def verify_webhook(headers, body)
      raise NotImplementedError
    end

    private
      # Links back into the app (return URLs) use the app's own host, set in
      # routes.default_url_options for each environment.
      def url_helpers
        Rails.application.routes.url_helpers
      end
  end
end
