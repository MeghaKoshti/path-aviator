class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Dates and times on every page are in the signed-in user's own zone.
  around_action :use_user_time_zone
  before_action :track_week_two_return

  private
    # Activation: coming back in the second week after signing up.
    def track_week_two_return
      user = Current.user
      return unless user&.created_at&.between?(14.days.ago, 7.days.ago)

      Event.track_once(:returned_week_2, user: user)
    end

    def use_user_time_zone(&)
      Time.use_zone(resume_session&.user&.zone || Time.zone_default, &)
    end
end
