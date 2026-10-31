class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Dates and times on every page are in the signed-in user's own zone.
  around_action :use_user_time_zone

  private
    def use_user_time_zone(&)
      Time.use_zone(resume_session&.user&.zone || Time.zone_default, &)
    end
end
