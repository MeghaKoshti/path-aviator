require "test_helper"

class LegalPagesControllerTest < ActionDispatch::IntegrationTest
  PAGES = {
    privacy: "Privacy Policy",
    terms: "Terms of Service",
    refunds: "Refund & Cancellation Policy",
    contact: "Contact"
  }.freeze

  PAGES.each do |page, heading|
    test "#{page} is public, titled and dated" do
      get public_send(:"#{page}_path")

      assert_response :success
      assert_select "h1", heading
      assert_select "title", "#{heading} | Path Aviator"
      assert_select "time[datetime=?]", Legal::LAST_UPDATED.iso8601, text: I18n.l(Legal::LAST_UPDATED, format: :legal)
    end
  end

  test "the privacy notice names the data, subprocessors, retention, rights and grievance contact" do
    get privacy_path

    body = response.body
    [ "email address", "IP address", "user agent", "private notes", "learning" ].each { |data| assert_includes body, data }
    [ "Gemini API", "Hetzner", "Resend", "Dodo Payments" ].each { |company| assert_includes body, company }
    assert_select "h2", "How long we keep it"
    assert_select "h2", "Grievance officer"
    assert_includes body, "Data Protection Board of India"
    assert_select "nav[aria-labelledby=toc-heading] a[href='#grievance-officer']", "Grievance officer"
  end

  test "the refund policy matches billing: cancel at period end, 3-day grace" do
    get refunds_path

    assert_includes response.body, "until the end of the monthly or yearly period"
    assert_includes response.body, "Pro stays on for 3 days"
  end

  test "operator name and support email come from the environment" do
    with_env("LEGAL_OWNER_NAME" => "Megha Koshti", "SUPPORT_EMAIL" => "help@pathaviator.dev") do
      get contact_path
    end

    assert_select "a[href^='mailto:help@pathaviator.dev']"
    assert_includes response.body, "Megha Koshti"
    assert_select "[role=note]", count: 0
  end

  test "unset details show obvious placeholders and a warning" do
    with_env("LEGAL_OWNER_NAME" => nil, "SUPPORT_EMAIL" => nil) do
      get privacy_path
    end

    assert_select "[role=note]", /Placeholder details/
    assert_select "a[href^='mailto:support@example.com']"
  end

  test "every layout's footer links to the policies and contact page" do
    links = [ privacy_path, terms_path, refunds_path, contact_path ]

    get root_path # marketing layout
    links.each { |href| assert_select "footer nav[aria-label=Footer] a[href=?]", href }

    get new_registration_path # auth layout
    links.each { |href| assert_select "footer nav[aria-label=Footer] a[href=?]", href }

    sign_in_as users(:one)
    get dashboard_path # app layout
    links.each { |href| assert_select "footer nav[aria-label=Footer] a[href=?]", href }
  end

  private
    def with_env(values)
      old = values.keys.to_h { |key| [ key, ENV[key] ] }
      values.each { |key, value| ENV[key] = value }
      yield
    ensure
      old.each { |key, value| ENV[key] = value }
    end
end
