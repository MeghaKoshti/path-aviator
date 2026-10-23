class PagesController < ApplicationController
  allow_unauthenticated_access
  layout "marketing"

  # Public landing page. Signed-in people go straight to their dashboard.
  def home
    redirect_to dashboard_path if authenticated?
  end
end
