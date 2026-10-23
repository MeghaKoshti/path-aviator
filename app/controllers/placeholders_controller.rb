# Placeholder — implemented in feature stories.
# These pages exist so the app shell and landing page links never 500.
# Replace each route in config/routes.rb with the real controller, then delete this file.
class PlaceholdersController < ApplicationController
  allow_unauthenticated_access only: :new_registration
  layout -> { action_name == "new_registration" ? "auth" : "application" }

  def dashboard
    render_placeholder "Your dashboard is on its way", "Your learning paths will appear here once path planning is live."
  end

  def new_learning_goal
    render_placeholder "Planning new paths is coming soon", "You’ll be able to pick a topic, level and weekly hours here."
  end

  def settings
    render_placeholder "Account settings are coming soon", "You’ll be able to update your name, email and password here."
  end

  def new_registration
    render_placeholder "Sign-ups open soon", "Creating an account isn’t available yet. If you already have one, sign in instead."
  end

  private
    def render_placeholder(title, body)
      @title, @body = title, body
      render :show
    end
end
