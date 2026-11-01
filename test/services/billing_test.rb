require "test_helper"
require "minitest/mock"

class BillingTest < ActiveSupport::TestCase
  Request = Struct.new(:headers)

  test "uses the fake provider outside production unless told otherwise" do
    with_env("BILLING_PROVIDER" => nil) do
      assert_instance_of Billing::FakeProvider, Billing.provider
      assert Billing.available?
    end
    with_env("BILLING_PROVIDER" => "dodo", "DODO_API_KEY" => nil) do
      assert_instance_of Billing::Dodo, Billing.provider
      assert_not Billing.available?
    end
  end

  test "never hands out the fake provider in production" do
    Rails.env.stub(:production?, true) do
      with_env("BILLING_PROVIDER" => "fake") do
        assert_raises(Billing::NotConfigured) { Billing.provider }
        assert_not Billing.available?
      end
      with_env("BILLING_PROVIDER" => nil) do
        assert_equal "dodo", Billing.provider_name
      end
    end
  end

  test "an unknown provider name is a configuration error" do
    assert_raises(Billing::NotConfigured) { Billing.provider("paypal") }
  end

  test "Indian visitors see rupees, everyone else dollars" do
    assert_equal "inr", Billing.currency_for(Request.new({ "CF-IPCountry" => "IN" }))
    assert_equal "usd", Billing.currency_for(Request.new({ "CF-IPCountry" => "DE", "Accept-Language" => "en-IN" }))
    assert_equal "inr", Billing.currency_for(Request.new({ "Accept-Language" => "en-IN,en;q=0.9" }))
    assert_equal "usd", Billing.currency_for(Request.new({ "Accept-Language" => "en-US,en;q=0.9" }))
    assert_equal "usd", Billing.currency_for(Request.new({}))
  end
end
