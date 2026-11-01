require "openssl"
require "base64"

module Billing
  # Signing and checking webhooks the Standard Webhooks way
  # (https://www.standardwebhooks.com/), as Dodo Payments does:
  # https://docs.dodopayments.com/developer-resources/webhooks.md
  #
  # - headers webhook-id, webhook-timestamp (Unix seconds), webhook-signature
  # - signed content "#{id}.#{timestamp}.#{raw body}"
  # - HMAC-SHA256 keyed with the secret: strip "whsec_", then base64-decode
  # - the header holds space-separated "v1,<base64 signature>" entries; any match is valid
  # - timestamps more than 5 minutes off are rejected, so old requests can't be replayed
  module StandardWebhooks
    TOLERANCE = 5.minutes

    module_function

    def verify!(secret:, headers:, body:, now: Time.current)
      id, timestamp, signatures = headers.values_at("webhook-id", "webhook-timestamp", "webhook-signature")
      raise SignatureError, "Missing webhook headers" if [ id, timestamp, signatures ].any?(&:blank?)
      raise SignatureError, "Bad webhook timestamp" unless timestamp.to_s.match?(/\A\d+\z/)
      raise SignatureError, "Webhook timestamp is too old or too new" if (now.to_i - timestamp.to_i).abs > TOLERANCE

      expected = signature(secret:, id:, timestamp:, body:)
      valid = signatures.to_s.split.any? do |entry|
        version, value = entry.split(",", 2)
        version == "v1" && value.present? && ActiveSupport::SecurityUtils.secure_compare(value, expected)
      end
      raise SignatureError, "Webhook signature doesn't match" unless valid

      true
    end

    # The headers a sender attaches; used by the fake provider and tests.
    def headers_for(secret:, id:, body:, timestamp: Time.current.to_i)
      {
        "webhook-id" => id,
        "webhook-timestamp" => timestamp.to_s,
        "webhook-signature" => "v1,#{signature(secret:, id:, timestamp:, body:)}"
      }
    end

    def signature(secret:, id:, timestamp:, body:)
      Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", key(secret), "#{id}.#{timestamp}.#{body}"))
    end

    def key(secret)
      raise SignatureError, "No webhook secret configured" if secret.blank?

      Base64.decode64(secret.delete_prefix("whsec_"))
    end
  end
end
