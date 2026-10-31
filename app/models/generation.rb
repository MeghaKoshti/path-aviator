# One AI call: a new path or a regeneration (kind "path"), or a substitute for
# a broken link (kind "link_replacement"). These rows are the meter for the
# per-user monthly quota (paths only) and the global daily cost cap (all).
class Generation < ApplicationRecord
  DEFAULT_DAILY_LIMIT = 500

  belongs_to :user
  # Optional because the path may be deleted later; the row stays so deleting
  # a path never hands quota back.
  belongs_to :learning_path, optional: true

  KINDS = %w[path link_replacement].freeze
  validates :kind, inclusion: { in: KINDS }

  # What uses up the monthly quota: paths the user asked for. A generation
  # that failed on our side doesn't, and automatic link replacements don't,
  # but both cost money, so they count towards the daily cap.
  scope :counted, -> { where(kind: "path", failed_at: nil) }

  class << self
    # Global brake on the Gemini bill, whatever plans people are on.
    def daily_limit
      Integer(ENV.fetch("AI_DAILY_GENERATION_LIMIT", DEFAULT_DAILY_LIMIT))
    end

    def daily_limit_reached?(now: Time.current)
      where(created_at: now.all_day).count >= daily_limit
    end

    # Marks the latest generation for a path as failed (see GenerateLearningPathJob).
    def fail_latest_for(learning_path)
      where(learning_path_id: learning_path.id, failed_at: nil).order(:id).last&.update!(failed_at: Time.current)
    end
  end
end
