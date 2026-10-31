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

  def share_image_url
    image_url("og-card.png")
  end
end
