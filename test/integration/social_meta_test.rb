require "test_helper"

class SocialMetaTest < ActionDispatch::IntegrationTest
  def assert_share_tags(title:, url:)
    assert_select "meta[property='og:title'][content=?]", title
    assert_select "meta[name='twitter:title'][content=?]", title
    assert_select "meta[property='og:url'][content=?]", url
    assert_select "meta[property='og:description'][content]"
    assert_select "meta[name='twitter:card'][content=summary_large_image]"
    assert_select "meta[property='og:image'][content^='http://www.example.com/assets/og-card']"
    assert_select "meta[property='og:image:width'][content='1200']"
  end

  test "landing and pricing have share previews" do
    get root_path
    assert_share_tags title: "Turn a job post into a study plan you’ll finish", url: "http://www.example.com/"

    get pricing_path(currency: "inr")
    assert_share_tags title: "Pricing", url: "http://www.example.com/pricing"
  end

  test "a shared path's preview says who is learning it" do
    path = learning_paths(:rails)
    path.share!

    get shared_path_path(path.share_token)

    assert_share_tags title: "Riya is learning: Ruby on Rails from zero to deploy", url: shared_path_url(path.share_token)
    assert_select "meta[property='og:description'][content^=?]", "1 of 4 steps done."
  end

  test "the share image is a real 1200×630 PNG" do
    png = Rails.root.join("app/assets/images/og-card.png").binread
    width, height = png[16, 8].unpack("NN")

    assert_equal "\x89PNG".b, png[0, 4]
    assert_equal [ 1200, 630 ], [ width, height ]
  end
end

class SeoFoundationsTest < ActionDispatch::IntegrationTest
  test "the landing page describes the app as a SoftwareApplication with prices from the plan catalog" do
    get root_path

    data = JSON.parse(css_select("script[type='application/ld+json']").sole.text)
    assert_equal "SoftwareApplication", data["@type"]
    prices = data["offers"].map { |offer| [ offer["priceCurrency"], offer["price"] ] }
    assert_includes prices, [ "INR", "199.00" ]
    assert_includes prices, [ "USD", "6.00" ]
  end

  test "public pages each have a unique title and description and a canonical link without query strings" do
    pages = [ root_path, pricing_path, learn_topics_path, privacy_path, terms_path, refunds_path, contact_path ] +
            LearnTopic.all.map { |topic| learn_topic_path(topic) }

    seen = pages.map do |page|
      get page, params: { currency: "inr" }
      assert_select "link[rel=canonical][href=?]", "http://www.example.com#{page}"
      [ css_select("title").text, css_select("meta[name=description]").first["content"] ]
    end

    assert_equal seen.size, seen.map(&:first).uniq.size, "duplicate titles"
    assert_equal seen.size, seen.map(&:last).uniq.size, "duplicate descriptions"
  end

  test "private share pages stay noindex" do
    path = learning_paths(:rails)
    path.share!

    get shared_path_path(path.share_token)

    assert_select "meta[name=robots][content=noindex]"
    assert_equal "noindex", response.headers["X-Robots-Tag"]
  end
end
