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
