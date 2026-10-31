module BillingTestHelper
  # A made-up signing secret in Standard Webhooks form; never a real one.
  DODO_TEST_SECRET = "whsec_#{Base64.strict_encode64("path-aviator-test-webhook-secret")}".freeze
  DODO_PRODUCT_IDS = {
    [ "month", "inr" ] => "pdt_pro_monthly_inr", [ "year", "inr" ] => "pdt_pro_yearly_inr",
    [ "month", "usd" ] => "pdt_pro_monthly_usd", [ "year", "usd" ] => "pdt_pro_yearly_usd"
  }.freeze

  # Records requests and replies with canned responses instead of the network.
  class FakeHttp
    attr_reader :requests

    def initialize(*responses)
      @responses = responses
      @requests = []
    end

    def post_json(url, body:, headers: {})
      @requests << { url: url, body: body.presence && JSON.parse(body), headers: headers }
      status, body = @responses.shift || [ 200, "{}" ]
      Billing::HttpClient::Response.new(status: status, body: body)
    end
  end

  def dodo_provider(http: FakeHttp.new, **options)
    Billing::Dodo.new(api_key: "test_api_key", webhook_secret: DODO_TEST_SECRET, environment: "test_mode",
                      product_ids: DODO_PRODUCT_IDS, http: http, **options)
  end

  # A recorded Dodo webhook (test/fixtures/files/dodo) for this user, signed
  # with the test secret. Returns [headers, body].
  def dodo_webhook(name, user:, id: "msg_#{SecureRandom.hex(8)}", timestamp: Time.current.to_i, secret: DODO_TEST_SECRET)
    body = file_fixture("dodo/#{name}.json").read.gsub("USER_ID", user.id.to_s)
    [ Billing::StandardWebhooks.headers_for(secret: secret, id: id, body: body, timestamp: timestamp), body ]
  end
end
