# Placeholder — implemented in feature stories.
# These pages exist so the app shell and landing page links never 500.
# Replace each route in config/routes.rb with the real controller, then delete this file.
class PlaceholdersController < ApplicationController
  def settings
    render_placeholder "Account settings are coming soon", "You’ll be able to update your name, email and password here."
  end

  private
    def render_placeholder(title, body)
      @title, @body = title, body
      render :show
    end
end
