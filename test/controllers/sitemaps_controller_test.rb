require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  test "the sitemap lists the public pages and every study plan, and no private links" do
    path = learning_paths(:rails)
    path.share!

    get sitemap_path

    assert_response :success
    assert_equal "application/xml", response.media_type
    xml = Nokogiri::XML(response.body)
    xml.remove_namespaces!
    locs = xml.xpath("//url/loc").map(&:text)
    expected = [ root_url, pricing_url, learn_topics_url, privacy_url, terms_url, refunds_url, contact_url ] +
               LearnTopic.all.map { |topic| learn_topic_url(topic) }
    assert_equal expected.sort, locs.sort
    assert locs.none? { |loc| loc.include?("/p/") || loc.include?("/c/") }
    assert_equal LearnTopic.all.first.checked_on.iso8601, xml.at_xpath("//url[loc='#{learn_topic_url(LearnTopic.all.first)}']/lastmod").text
  end

  test "robots.txt points at the sitemap and keeps crawlers out of the app" do
    get "/robots.txt"

    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_includes response.body, "Sitemap: http://www.example.com/sitemap.xml"
    %w[ /dashboard /learning_paths /settings ].each { |path| assert_includes response.body, "Disallow: #{path}" }
    assert_not_includes response.body, "Disallow: /learn\n"
  end
end
