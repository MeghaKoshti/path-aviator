# Taking money for Pro, behind one interface so the payment provider can be
# swapped (Dodo Payments now, Razorpay or anything else later).
#
#   Billing.provider.create_checkout(user:, plan: Plan.pro, interval: "month", currency: "inr")
#   # => Billing::Checkout(url: "https://...")
#
# Every provider implements Billing::Provider. Billing::FakeProvider stands in
# for the real thing in development and tests, so the whole upgrade flow works
# offline.
module Billing
  class Error < StandardError; end
  # The provider isn't set up (missing keys), so nobody can pay.
  class NotConfigured < Error; end
  class RequestFailed < Error; end
  # A webhook that wasn't signed by the provider, or is too old to trust.
  class SignatureError < Error; end

  INTERVALS = %w[month year].freeze
  CURRENCIES = %w[inr usd].freeze

  Checkout = Data.define(:url)

  # A provider's webhook translated into our terms. type is one of
  # EVENT_TYPES, or nil for events we don't act on.
  Event = Data.define(:id, :type, :occurred_at, :subscription, :raw)
  EVENT_TYPES = %w[activated renewed payment_failed canceled expired updated].freeze

  # The subscription as the provider describes it in an event.
  SubscriptionInfo = Data.define(:external_id, :customer_id, :user_id, :email, :interval, :currency,
                                 :current_period_end, :cancel_at_period_end)

  class << self
    # Which provider takes payments: BILLING_PROVIDER, or Dodo in production
    # and the fake one everywhere else.
    def provider_name
      ENV["BILLING_PROVIDER"].presence || (Rails.env.production? ? "dodo" : "fake")
    end

    def provider(name = provider_name)
      case name.to_s
      when "fake"
        # A fake checkout in production would hand out Pro for free.
        raise NotConfigured, "The fake billing provider is not available in production" if Rails.env.production?

        FakeProvider.new
      when "dodo" then Dodo.new
      else raise NotConfigured, "Unknown billing provider: #{name}"
      end
    end

    # Whether Upgrade buttons should be shown at all.
    def available?
      provider.configured?
    rescue NotConfigured
      false
    end

    # Indian visitors pay in rupees, everyone else in dollars. Without a
    # country header from the proxy, an Indian browser locale is the hint.
    def currency_for(request)
      country = request.headers["CF-IPCountry"].presence
      return country.casecmp?("IN") ? "inr" : "usd" if country

      request.headers["Accept-Language"].to_s.match?(/\b[a-z]{2}-IN\b/i) ? "inr" : "usd"
    end
  end
end
