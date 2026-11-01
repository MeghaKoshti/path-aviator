require "test_helper"

class Billing::StandardWebhooksTest < ActiveSupport::TestCase
  SECRET = BillingTestHelper::DODO_TEST_SECRET

  def headers(body, **options)
    Billing::StandardWebhooks.headers_for(secret: SECRET, id: "msg_1", body: body, **options)
  end

  test "matches the reference vector from the Standard Webhooks spec" do
    signature = Billing::StandardWebhooks.signature(
      secret: "whsec_MfKQ9r8GKYqrTwjUPD8ILPZIo2LaLaSw", id: "msg_p5jXN8AQM9LWM0D4loKWxJek",
      timestamp: 1614265330, body: '{"test": 2432232314}'
    )

    assert_equal "g0hM9SsE+OTPJTGt/tmIKtSyZlE3uFJELVlNIOLJ1OE=", signature
  end

  test "accepts a correctly signed request" do
    assert Billing::StandardWebhooks.verify!(secret: SECRET, headers: headers("{}"), body: "{}")
  end

  test "rejects a changed body or a different secret" do
    signed = headers('{"plan":"free"}')

    assert_raises(Billing::SignatureError) { Billing::StandardWebhooks.verify!(secret: SECRET, headers: signed, body: '{"plan":"pro"}') }
    other = "whsec_#{Base64.strict_encode64("someone-else")}"
    assert_raises(Billing::SignatureError) { Billing::StandardWebhooks.verify!(secret: other, headers: signed, body: '{"plan":"free"}') }
  end

  test "accepts any matching v1 signature among several (secret rotation)" do
    signed = headers("{}")
    signed["webhook-signature"] = "v1,bm90LXRoaXMtb25l #{signed["webhook-signature"]}"

    assert Billing::StandardWebhooks.verify!(secret: SECRET, headers: signed, body: "{}")
  end

  test "ignores signatures from other schemes" do
    signed = headers("{}")
    signed["webhook-signature"] = signed["webhook-signature"].sub("v1,", "v1a,")

    assert_raises(Billing::SignatureError) { Billing::StandardWebhooks.verify!(secret: SECRET, headers: signed, body: "{}") }
  end

  test "rejects timestamps more than five minutes away, either way" do
    now = Time.current
    fresh = headers("{}", timestamp: (now - 4.minutes).to_i)
    stale = headers("{}", timestamp: (now - 6.minutes).to_i)
    future = headers("{}", timestamp: (now + 6.minutes).to_i)

    assert Billing::StandardWebhooks.verify!(secret: SECRET, headers: fresh, body: "{}", now: now)
    error = assert_raises(Billing::SignatureError) { Billing::StandardWebhooks.verify!(secret: SECRET, headers: stale, body: "{}", now: now) }
    assert_match "too old", error.message
    assert_raises(Billing::SignatureError) { Billing::StandardWebhooks.verify!(secret: SECRET, headers: future, body: "{}", now: now) }
  end

  test "rejects missing headers and a missing secret" do
    assert_raises(Billing::SignatureError) { Billing::StandardWebhooks.verify!(secret: SECRET, headers: {}, body: "{}") }
    assert_raises(Billing::SignatureError) { Billing::StandardWebhooks.verify!(secret: nil, headers: headers("{}"), body: "{}") }
  end
end
