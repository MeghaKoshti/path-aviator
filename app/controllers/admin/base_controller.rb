# Everything under /admin. Non-admins (and signed-out visitors) get the same
# 404 as a page that doesn't exist, so the admin area isn't advertised.
class Admin::BaseController < ApplicationController
  allow_unauthenticated_access
  before_action :require_admin

  private
    def require_admin
      return if authenticated? && Current.user.admin?

      render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
    end
end
