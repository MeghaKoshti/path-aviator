# Runs every hour (config/recurring.yml) and emails each user whose local
# time is Sunday, 6pm, so everyone gets the check-in on their own Sunday
# evening. weekly_digest_sent_at keeps a re-run from sending twice.
class WeeklyDigestJob < ApplicationJob
  SEND_HOUR = 18
  ACTIVE_WITHIN = 30.days

  queue_as :default

  def perform(now: Time.current)
    User.where(weekly_digest: true).find_each do |user|
      next unless due?(user, now) && eligible?(user, now)

      WeeklyDigestMailer.check_in(user).deliver_later
      user.update_column(:weekly_digest_sent_at, now)
    end
  end

  private
    def due?(user, now)
      local = now.in_time_zone(user.zone)
      local.sunday? && local.hour == SEND_HOUR && (user.weekly_digest_sent_at.nil? || user.weekly_digest_sent_at < now - 6.days)
    end

    # Never the shared demo account, never an unverified address (once email
    # verification exists), and only people who learned something lately.
    def eligible?(user, now)
      return false if user.demo?
      return false if user.respond_to?(:email_verified_at) && user.email_verified_at.nil?

      PathStep.owned_by(user).where(completed_at: (now - ACTIVE_WITHIN)..).exists? ||
        user.learning_goals.where(created_at: (now - ACTIVE_WITHIN)..).exists?
    end
end
