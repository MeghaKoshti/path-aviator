# Public, indexable pages only. Share links (/p/…) and certificates (/c/…) are private and noindex.
xml.instruct!
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  [ root_url, pricing_url, learn_topics_url, privacy_url, terms_url, refunds_url, contact_url ].each do |url|
    xml.url { xml.loc url }
  end

  @topics.each do |topic|
    xml.url do
      xml.loc learn_topic_url(topic)
      xml.lastmod topic.checked_on.iso8601
    end
  end
end
