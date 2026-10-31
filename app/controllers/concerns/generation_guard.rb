# Every AI generation goes through here. The plan's monthly quota and the
# global daily cap are checked before a job is queued, and each generation is
# recorded so that it counts.
module GenerationGuard
  extend ActiveSupport::Concern

  RATE_LIMIT_MESSAGE = "You’re planning paths very quickly. Please wait a few minutes and try again.".freeze

  included do
    helper_method :generation_quota
  end

  private
    def generation_quota
      @generation_quota ||= Current.user.generation_quota
    end

    # The reason a generation can't start now, or nil when it can.
    def generation_refusal
      reason = generation_quota.refusal
      if reason == :busy
        Rails.logger.warn("[AI cost guard] daily limit of #{Generation.daily_limit} generations reached; refused user #{Current.user.id}")
      end
      reason
    end

    def record_generation(learning_path)
      Current.user.generations.create!(learning_path: learning_path)
    end
end
