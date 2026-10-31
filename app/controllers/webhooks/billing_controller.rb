# POST /webhooks/billing/:provider
#
# Called by the payment provider's servers, not a browser: no session, no
# CSRF token and no browser check (hence ActionController::API). The
# signature is what proves the request is genuine.
class Webhooks::BillingController < ActionController::API
  def create
    provider = Billing.provider(params[:provider])
    result = Billing::WebhookReceiver.call(provider, signature_headers, request.raw_post)

    Rails.logger.info("[Billing] #{provider.name} webhook #{request.headers["webhook-id"]}: #{result.status}")
    # Duplicates and events we don't act on are still a success, or the
    # provider would keep retrying them.
    head :ok
  rescue Billing::NotConfigured
    head :not_found
  rescue Billing::SignatureError => e
    Rails.logger.warn("[Billing] rejected #{params[:provider]} webhook: #{e.message}")
    head :unauthorized
  end

  private
    # Lower-case names, the way the adapters read them.
    def signature_headers
      %w[webhook-id webhook-timestamp webhook-signature x-razorpay-signature x-razorpay-event-id].to_h do |name|
        [ name, request.headers[name] ]
      end
    end
end
