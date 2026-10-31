require "test_helper"

class PricingControllerTest < ActionDispatch::IntegrationTest
  test "guests see Free and Pro in dollars by default, monthly, with the billing interval spelled out" do
    get pricing_path

    assert_response :success
    assert_select "h1", /Free to start/
    assert_select "#pro-plan", "Pro"
    assert_select "[data-currency=usd][data-interval=month]:not([hidden])", /\$6\s+per month/
    assert_select "[data-currency=usd][data-interval=month]:not([hidden])", /Billed monthly/
    assert_select "[data-currency=inr][data-interval=month][hidden]", /₹199/
    assert_select "[data-currency=usd][data-interval=year][hidden]", /\$48.*about \$4 a month/m
    assert_select "[data-currency=inr][data-interval=year][hidden]", /₹1,499.*about ₹125 a month/m
    assert_select "button[aria-pressed=true][data-value=month]", "Monthly"
    assert_select "button[aria-pressed=true][data-value=usd]", "$ USD"
    assert_select "a[href=?]", new_registration_path, text: "Get Pro"
  end

  test "an Indian browser locale gets rupees" do
    get pricing_path, headers: { "Accept-Language" => "en-IN,en;q=0.9" }

    assert_select "[data-currency=inr][data-interval=month]:not([hidden])", /₹199/
    assert_select "button[aria-pressed=true][data-value=inr]"
    assert_select "[data-controller=pricing][data-pricing-chosen-value=false]"
  end

  test "an explicit currency and interval win over the browser locale" do
    get pricing_path(currency: "usd", interval: "year"), headers: { "Accept-Language" => "hi-IN" }

    assert_select "[data-currency=usd][data-interval=year]:not([hidden])", /\$48/
    assert_select "[data-controller=pricing][data-pricing-chosen-value=true]"
  end

  test "the yearly badge shows the saving per currency" do
    get pricing_path

    assert_select "[data-currency=inr]", "Save 37%"
    assert_select "[data-currency=usd]", "Save 33%"
  end

  test "the comparison table and FAQ come from the plan catalog" do
    get pricing_path

    assert_select "table th[scope=row]", "New learning paths each month"
    assert_select "table tr", /New learning paths each month\s+#{Plan.free.monthly_generations}\s+Unlimited/
    assert_select "details summary", /How is this different from asking ChatGPT/
    assert_select "details", /Every link is checked/
    assert_select "details a[href=?]", refunds_path
  end

  test "signed-in free users see a clear next step until checkout exists" do
    sign_in_as users(:one)

    get pricing_path

    assert_select "[aria-labelledby=pro-plan]", /Pro checkout opens soon/ unless respond_to?(:billing_checkout_path)
    assert_select "a[href=?]", new_registration_path, text: "Get Pro", count: 0
  end

  test "pricing is linked from the landing header, hero and footer" do
    get root_path

    assert_select "header a[href=?]", pricing_path, text: "Pricing"
    assert_select "main a[href=?]", pricing_path, text: "See pricing"
    assert_select "footer a[href=?]", pricing_path
  end
end
