# Sunday's short check-in: "4 h of 6 h, 3-day streak, next step: …".
# Sent by WeeklyDigestJob; everything is worked out in the user's time zone.
class WeeklyDigestMailer < ApplicationMailer
  helper LearningPathsHelper

  def check_in(user)
    @user = user
    Time.use_zone(user.zone) do
      @stats = LearningStats.new(user)
      @next_path = user.learning_paths.ready.includes(:learning_goal, :path_steps).order(updated_at: :desc).find { |path| !path.completed? }
      @next_step = @next_path&.next_step
      @unsubscribe_url = unsubscribe_url(user.generate_token_for(:unsubscribe))

      # Mail clients show their own "Unsubscribe" button for these (RFC 8058).
      headers["List-Unsubscribe"] = "<#{@unsubscribe_url}>"
      headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"

      mail to: user.email_address, subject: subject_line
    end
  end

  private
    def subject_line
      helpers = view_context
      learned = helpers.format_minutes(@stats.minutes_this_week)
      goal = @stats.weekly_goal_minutes
      parts = [ goal.positive? ? "#{learned} of #{helpers.format_minutes(goal)}" : "#{learned} learned" ]
      parts << "#{@stats.streak}-day streak" if @stats.streak.positive?
      "Your week: #{parts.join(", ")}"
    end
end
