# /sitemap.xml and /robots.txt. Dynamic so they use the app's real host.
class SitemapsController < ApplicationController
  allow_unauthenticated_access

  def show
    @topics = LearnTopic.all
    expires_in 6.hours, public: true
  end

  def robots
    expires_in 6.hours, public: true
    render plain: <<~ROBOTS
      User-agent: *
      Disallow: /dashboard
      Disallow: /learning_goals
      Disallow: /learning_paths
      Disallow: /path_steps
      Disallow: /settings
      Disallow: /passwords

      Sitemap: #{sitemap_url}
    ROBOTS
  end
end
