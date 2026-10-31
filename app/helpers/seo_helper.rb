# Title, description and share-preview (Open Graph / Twitter) tags for every page.
# Pages set content_for :title and :meta_description; :og_title overrides the
# preview title when it should read differently from the browser tab.
module SeoHelper
  DEFAULT_TITLE = "Path Aviator: turn a job post into a study plan".freeze
  DEFAULT_DESCRIPTION = "Paste a job post or name a skill. Path Aviator plans a week-by-week route with checked links " \
                        "and gives you a public progress page for your CV.".freeze

  def page_title
    content_for?(:title) ? safe_join([ content_for(:title), "Path Aviator" ], " | ") : DEFAULT_TITLE
  end

  def page_description
    content_for?(:meta_description) ? content_for(:meta_description) : DEFAULT_DESCRIPTION
  end

  def share_title
    return content_for(:og_title) if content_for?(:og_title)

    content_for?(:title) ? content_for(:title) : DEFAULT_TITLE
  end

  # The page's own address without query strings, so ?currency=… variants count as one page.
  def canonical_url
    request.base_url + request.path
  end

  # Structured data for search engines. json_escape keeps "</script>" in
  # any title from closing the tag early.
  def json_ld_tag(data)
    tag.script(ERB::Util.json_escape(data.to_json).html_safe, type: "application/ld+json") # rubocop:disable Rails/OutputSafety
  end

  def software_application_ld
    pro = Plan.pro
    offers = [ { "@type": "Offer", name: Plan.free.name, price: "0", priceCurrency: "USD" } ] +
      Plan::CURRENCIES.map do |currency|
        { "@type": "Offer", name: "#{pro.name}, monthly", price: format("%.2f", pro.price_cents(currency:, interval: :month) / 100.0),
          priceCurrency: currency.to_s.upcase }
      end
    { "@context": "https://schema.org", "@type": "SoftwareApplication", name: "Path Aviator", url: root_url,
      applicationCategory: "EducationalApplication", operatingSystem: "Web", description: SeoHelper::DEFAULT_DESCRIPTION,
      offers: offers }
  end

  def learn_topic_ld(topic)
    {
      "@context": "https://schema.org",
      "@graph": [
        { "@type": "Course", name: topic.title, description: topic.description, url: learn_topic_url(topic),
          educationalLevel: topic.level.capitalize, inLanguage: "en", isAccessibleForFree: true,
          timeRequired: "PT#{topic.total_minutes / 60}H",
          provider: { "@type": "Organization", name: "Path Aviator", url: root_url } },
        { "@type": "ItemList", name: "#{topic.title}: steps", numberOfItems: topic.steps.size,
          itemListElement: topic.steps.each_with_index.map { |step, index|
            { "@type": "ListItem", position: index + 1, name: step.title, url: step.url }
          } }
      ]
    }
  end

  def share_image_url
    image_url("og-card.png")
  end
end
