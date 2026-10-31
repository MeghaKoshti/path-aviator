# Account settings: profile, password and account deletion on one page.
# Each section posts to its own controller under Settings::, and on a failed
# save that controller re-renders this page with its section's errors.
class SettingsController < ApplicationController
  DEMO_LOCKED_NOTICE = "This is the shared demo account, so its settings are locked. Sign up to try them.".freeze

  # Everyone shares the demo login, so nobody may change or delete it. The page
  # disables the forms too, but this is the check that counts.
  before_action :keep_demo_account_locked, except: :show

  def show
    render_settings
  end

  private
    def keep_demo_account_locked
      redirect_to settings_path, notice: DEMO_LOCKED_NOTICE, status: :see_other if Current.user.demo?
    end

    # Forms get their own copy of the user, so unsaved changes never leak into
    # the nav (which shows Current.user).
    def render_settings(status: :ok)
      @profile ||= User.find(Current.user.id)
      @password_change ||= User.find(Current.user.id)
      render "settings/show", status: status
    end
end
