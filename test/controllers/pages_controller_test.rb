require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "guests see the landing page" do
    get root_path

    assert_response :success
    assert_select "h1", /Turn the job post into a plan/
    assert_select "title", /job post/
    assert_select "a[href=?]", new_registration_path, text: "Plan my first path"
    assert_select "a[href=?]", new_session_path, text: "Sign in"
    assert_select "a[href=?]", pricing_path, text: "See pricing"
    assert_select "h2", "How it works"
    assert_select "a[href='#main']", "Skip to main content"
    assert_select "main#main"
  end

  test "the pricing teaser shows Pro's monthly price in the visitor's currency" do
    get root_path, headers: { "Accept-Language" => "en-IN" }

    assert_select "#pricing-title", "Start free. Go Pro for the push."
    assert_select "[data-currency=inr]:not([hidden])", "₹199 a month"
    assert_select "[data-currency=usd][hidden]", "$6 a month"
  end

  test "signed-in users are sent to their dashboard" do
    sign_in_as users(:one)

    get root_path

    assert_redirected_to dashboard_path
  end
end
