# Account settings: profile, password and account deletion on one page.
# Each section posts to its own controller under Settings::, and on a failed
# save that controller re-renders this page with its section's errors.
class SettingsController < ApplicationController
  def show
    render_settings
  end

  private
    # Forms get their own copy of the user, so unsaved changes never leak into
    # the nav (which shows Current.user).
    def render_settings(status: :ok)
      @profile ||= User.find(Current.user.id)
      @password_change ||= User.find(Current.user.id)
      render "settings/show", status: status
    end
end
