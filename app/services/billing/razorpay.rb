module Billing
  # Razorpay Subscriptions (a payment gateway: Megha is the seller of record
  # and handles GST herself). The fallback, or the INR provider via
  # BILLING_PROVIDER_INR=razorpay. Docs this adapter follows:
  #
  # - Create a subscription, POST /v1/subscriptions (Basic auth key_id:key_secret)
  #   -> short_url, the hosted page where the customer authorises the mandate:
  #   https://razorpay.com/docs/api/payments/subscriptions/create-subscription/
  # - Cancel, POST /v1/subscriptions/:id/cancel with cancel_at_cycle_end:
  #   https://razorpay.com/docs/api/payments/subscriptions/cancel-subscription/
  # - Webhooks: HMAC-SHA256 hex digest of the raw body with the webhook secret
  #   in X-Razorpay-Signature; x-razorpay-event-id is unique per event:
  #   https://razorpay.com/docs/webhooks/validate-test/
  # - Subscription events (activated, charged, pending, halted, cancelled, completed, ...):
  #   https://razorpay.com/docs/webhooks/subscriptions/
  #
  # Razorpay has no hosted customer portal, so subscribers cancel from
  # settings (#cancel) and Razorpay emails them about failed charges.
  class Razorpay < Provider
    API = "https://api.razorpay.com/v1".freeze
    # Razorpay subscriptions need a fixed number of billing cycles; ten years.
    TOTAL_COUNTS = { "month" => 120, "year" => 10 }.freeze

    EVENT_TYPES = {
      "subscription.activated" => "activated",
      "subscription.charged" => "renewed",
      "subscription.pending" => "payment_failed",
      # Retries are exhausted; the customer has to act before it can restart.
      "subscription.halted" => "expired",
      "subscription.cancelled" => "canceled",
      "subscription.completed" => "expired",
      "subscription.updated" => "updated"
    }.freeze

    def initialize(key_id: ENV["RAZORPAY_KEY_ID"], key_secret: ENV["RAZORPAY_KEY_SECRET"],
                   webhook_secret: ENV["RAZORPAY_WEBHOOK_SECRET"], plan_ids: self.class.plan_ids_from_env, http: HttpClient.new)
      @key_id = key_id
      @key_secret = key_secret
      @webhook_secret = webhook_secret
      @plan_ids = plan_ids
      @http = http
    end

    # { ["month", "inr"] => "plan_...", ... } from RAZORPAY_PLAN_PRO_MONTHLY_INR and friends.
    def self.plan_ids_from_env
      { "month" => "MONTHLY", "year" => "YEARLY" }.flat_map do |interval, word|
        Billing::CURRENCIES.map { |currency| [ [ interval, currency ], ENV["RAZORPAY_PLAN_PRO_#{word}_#{currency.upcase}"] ] }
      end.to_h
    end

    def name = "razorpay"

    # Ready when the keys are set and at least the INR plans exist (USD is optional).
    def configured?
      [ @key_id, @key_secret, @webhook_secret ].all?(&:present?) &&
        Billing::INTERVALS.all? { |interval| @plan_ids[[ interval, "inr" ]].present? }
    end

    def create_checkout(user:, plan:, interval:, currency:)
      plan_id = @plan_ids[[ interval.to_s, currency.to_s ]]
      raise NotConfigured, "No Razorpay plan for #{plan.key} #{interval} #{currency}" if plan_id.blank?

      response = post("/subscriptions", subscription_body(user, plan_id, interval, currency))
      Checkout.new(url: response.json.fetch("short_url"))
    rescue KeyError, JSON::ParserError
      raise RequestFailed, "Razorpay subscription response had no short_url"
    end

    def subscription_body(user, plan_id, interval, currency)
      {
        plan_id: plan_id,
        total_count: TOTAL_COUNTS.fetch(interval.to_s),
        quantity: 1,
        customer_notify: true,
        # Comes back on every webhook, so events can find the user.
        notes: { user_id: user.id.to_s, email: user.email_address, interval: interval.to_s, currency: currency.to_s }
      }
    end

    # No hosted portal; settings offers #cancel instead.
    def portal_url(_subscription)
      nil
    end

    # Stops renewal; Pro stays until the end of the paid cycle.
    def cancel(subscription)
      post("/subscriptions/#{ERB::Util.url_encode(subscription.external_id)}/cancel", { cancel_at_cycle_end: true })
      true
    end

    def verify_webhook(headers, body)
      signature = headers["x-razorpay-signature"].to_s
      raise SignatureError, "Missing X-Razorpay-Signature" if signature.blank?
      raise SignatureError, "No Razorpay webhook secret configured" if @webhook_secret.blank?

      expected = OpenSSL::HMAC.hexdigest("SHA256", @webhook_secret, body)
      raise SignatureError, "Razorpay signature doesn't match" unless ActiveSupport::SecurityUtils.secure_compare(signature, expected)

      payload = JSON.parse(body)
      Event.new(
        # The event id header isn't signed, so fall back to something that is.
        id: headers["x-razorpay-event-id"].presence || Digest::SHA256.hexdigest(body),
        type: EVENT_TYPES[payload["event"]],
        occurred_at: payload["created_at"] && Time.zone.at(payload["created_at"]),
        subscription: subscription_info(payload),
        raw: payload
      )
    rescue JSON::ParserError
      raise SignatureError, "Webhook body is not JSON"
    end

    private
      def post(path, body)
        auth = Base64.strict_encode64("#{@key_id}:#{@key_secret}")
        response = @http.post_json("#{API}#{path}", body: body.to_json, headers: { "Authorization" => "Basic #{auth}" })
        raise RequestFailed, "Razorpay returned HTTP #{response.status} for #{path}" unless response.success?

        response
      end

      def subscription_info(payload)
        entity = payload.dig("payload", "subscription", "entity") || {}
        notes = entity["notes"].is_a?(Hash) ? entity["notes"] : {}

        SubscriptionInfo.new(
          external_id: entity["id"],
          customer_id: entity["customer_id"],
          user_id: notes["user_id"],
          email: notes["email"] || payload.dig("payload", "payment", "entity", "email"),
          # Razorpay keeps these on the plan, so we read back our own notes.
          interval: notes["interval"].presence_in(Billing::INTERVALS),
          currency: notes["currency"].presence_in(Billing::CURRENCIES),
          current_period_end: entity["current_end"] && Time.zone.at(entity["current_end"]),
          # Razorpay doesn't report a cancel-at-cycle-end flag, so nil keeps
          # the one we set when the subscriber cancelled in settings.
          cancel_at_period_end: nil
        )
      end
  end
end
