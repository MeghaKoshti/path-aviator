module Billing
  # Dodo Payments (merchant of record: it charges the customer, files GST/VAT
  # and pays us out). Docs this adapter follows:
  #
  # - Checkout sessions, POST /checkouts -> checkout_url:
  #   https://docs.dodopayments.com/developer-resources/checkout-session.md
  #   https://docs.dodopayments.com/api-reference/checkout-sessions/create.md
  # - Customer portal, POST /customers/{customer_id}/customer-portal/session -> link (valid 24 h):
  #   https://docs.dodopayments.com/api-reference/customers/create-customer-portal-session.md
  # - Hosts: https://test.dodopayments.com and https://live.dodopayments.com, separate keys per mode:
  #   https://docs.dodopayments.com/miscellaneous/test-mode-vs-live-mode.md
  # - Webhooks follow Standard Webhooks (see Billing::StandardWebhooks); payload is
  #   { business_id, type, timestamp, data } and subscription events carry the subscription:
  #   https://docs.dodopayments.com/developer-resources/webhooks.md
  #   https://docs.dodopayments.com/developer-resources/webhooks/intents/subscription.md
  #   https://docs.dodopayments.com/api-reference/subscriptions/get-subscriptions.md (subscription fields)
  #
  # Each price is a subscription product created in the Dodo dashboard, with
  # its id in DODO_PRODUCT_PRO_{MONTHLY,YEARLY}_{INR,USD}. Indian prices are
  # set up tax-inclusive (₹199 incl. GST); Dodo shows the tax line.
  class Dodo < Provider
    HOSTS = { "test_mode" => "https://test.dodopayments.com", "live_mode" => "https://live.dodopayments.com" }.freeze

    # Dodo's event names mapped to ours (Billing::EVENT_TYPES). Anything else,
    # e.g. payment.succeeded which always comes with subscription.renewed, is ignored.
    EVENT_TYPES = {
      "subscription.active" => "activated",
      "subscription.renewed" => "renewed",
      "subscription.on_hold" => "payment_failed",
      "subscription.past_due" => "payment_failed",
      "subscription.cancelled" => "canceled",
      "subscription.expired" => "expired",
      "subscription.failed" => "expired",
      "subscription.updated" => "updated",
      "subscription.plan_changed" => "updated"
    }.freeze

    INTERVALS = { "Month" => "month", "Year" => "year" }.freeze

    def initialize(api_key: ENV["DODO_API_KEY"], webhook_secret: ENV["DODO_WEBHOOK_SECRET"],
                   environment: ENV.fetch("DODO_ENVIRONMENT", "test_mode"), product_ids: self.class.product_ids_from_env,
                   http: HttpClient.new)
      @api_key = api_key
      @webhook_secret = webhook_secret
      @host = HOSTS.fetch(environment) { raise NotConfigured, "DODO_ENVIRONMENT must be test_mode or live_mode" }
      @product_ids = product_ids
      @http = http
    end

    # { ["month", "inr"] => "pdt_...", ... } from DODO_PRODUCT_PRO_MONTHLY_INR and friends.
    def self.product_ids_from_env
      { "month" => "MONTHLY", "year" => "YEARLY" }.flat_map do |interval, word|
        Billing::CURRENCIES.map { |currency| [ [ interval, currency ], ENV["DODO_PRODUCT_PRO_#{word}_#{currency.upcase}"] ] }
      end.to_h
    end

    def name = "dodo"

    def configured?
      @api_key.present? && @webhook_secret.present? && @product_ids.values.all?(&:present?)
    end

    def create_checkout(user:, plan:, interval:, currency:)
      product_id = @product_ids[[ interval.to_s, currency.to_s ]]
      raise NotConfigured, "No Dodo product for #{plan.key} #{interval} #{currency}" if product_id.blank?

      response = post("/checkouts", checkout_body(user, product_id, interval, currency))
      Checkout.new(url: response.json.fetch("checkout_url"))
    rescue KeyError, JSON::ParserError
      raise RequestFailed, "Dodo checkout response had no checkout_url"
    end

    def checkout_body(user, product_id, interval, currency)
      customer_id = user.subscriptions.where(provider: name).where.not(customer_id: nil).pick(:customer_id)

      {
        product_cart: [ { product_id: product_id, quantity: 1 } ],
        customer: customer_id ? { customer_id: customer_id } : { email: user.email_address, name: user.name.presence || user.email_address },
        return_url: url_helpers.billing_return_url,
        # Copied onto the subscription, so webhooks can find the user.
        metadata: { user_id: user.id.to_s, plan: "pro", interval: interval.to_s, currency: currency.to_s }
      }
    end

    def portal_url(subscription)
      raise NotConfigured, "This subscription has no Dodo customer id" if subscription.customer_id.blank?

      query = { return_url: url_helpers.settings_url(anchor: "plan") }.to_query
      response = post("/customers/#{ERB::Util.url_encode(subscription.customer_id)}/customer-portal/session?#{query}", nil)
      response.json.fetch("link")
    rescue KeyError, JSON::ParserError
      raise RequestFailed, "Dodo portal response had no link"
    end

    def verify_webhook(headers, body)
      StandardWebhooks.verify!(secret: @webhook_secret, headers: headers, body: body)
      payload = JSON.parse(body)

      Event.new(
        id: headers["webhook-id"],
        type: EVENT_TYPES[payload["type"]],
        occurred_at: parse_time(payload["timestamp"]),
        subscription: subscription_info(payload["data"] || {}),
        raw: payload
      )
    rescue JSON::ParserError
      raise SignatureError, "Webhook body is not JSON"
    end

    private
      def post(path, body)
        response = @http.post_json("#{@host}#{path}", body: body&.to_json.to_s, headers: { "Authorization" => "Bearer #{@api_key}" })
        raise RequestFailed, "Dodo returned HTTP #{response.status} for #{path.split("?").first}" unless response.success?

        response
      end

      def subscription_info(data)
        SubscriptionInfo.new(
          external_id: data["subscription_id"],
          customer_id: data.dig("customer", "customer_id"),
          user_id: data.dig("metadata", "user_id"),
          email: data.dig("customer", "email"),
          interval: INTERVALS[data["payment_frequency_interval"]],
          # Dodo may charge in the buyer's local currency; then the price we
          # sold (from our checkout metadata) is what matters to us.
          currency: data["currency"].to_s.downcase.presence_in(Billing::CURRENCIES) || data.dig("metadata", "currency"),
          # The next charge marks the end of the period that's been paid for.
          current_period_end: parse_time(data["next_billing_date"]),
          cancel_at_period_end: data["cancel_at_next_billing_date"] == true
        )
      end

      def parse_time(value)
        Time.zone.parse(value) if value.present?
      end
  end
end
