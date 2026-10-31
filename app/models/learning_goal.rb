class LearningGoal < ApplicationRecord
  JOB_POST_MAX_LENGTH = 6_000
  # The earliest target date: less than two weeks is too short to plan steps for.
  MIN_LEAD_TIME = 2.weeks
  MAX_LEAD_TIME = 2.years

  belongs_to :user
  has_one :learning_path, dependent: :destroy

  enum :current_level, { beginner: 0, intermediate: 1, advanced: 2 }, validate: true

  # Set by the "I have a job post" form, so a blank post is an error there.
  attribute :from_job_post, :boolean, default: false

  normalizes :topic, with: ->(topic) { topic.squish }
  normalizes :goal_description, with: ->(text) { text.strip.presence }
  # Contact details never reach the database or the LLM.
  normalizes :job_post, with: ->(text) { PiiScrubber.call(text.strip).presence }

  validates :topic, presence: true, length: { in: 3..100 }
  validates :hours_per_week, presence: true,
                             numericality: { only_integer: true, in: 1..40 }
  validates :goal_description, length: { maximum: 500 }
  validates :job_post, presence: { if: :from_job_post }, length: { maximum: JOB_POST_MAX_LENGTH }
  validate :target_date_is_reachable, if: -> { target_date.present? && target_date_changed? }
  validate :job_post_allowed, if: -> { job_post.present? && new_record? }

  def job_post?
    job_post.present?
  end

  # Whole weeks from today to the target date (at least 1), or nil without one.
  def weeks_left(today: Date.current)
    return unless target_date

    [ ((target_date - today) / 7.0).ceil, 1 ].max
  end

  # The minutes the learner can spend before the target date at their pace.
  def minutes_until_target(today: Date.current)
    weeks_left(today:)&.then { |weeks| weeks * hours_per_week.to_i * 60 }
  end

  private
    def target_date_is_reachable
      today = Date.current
      if target_date < today + MIN_LEAD_TIME
        errors.add(:target_date, "must be at least two weeks from today")
      elsif target_date > today + MAX_LEAD_TIME
        errors.add(:target_date, "must be within two years")
      end
    end

    def job_post_allowed
      errors.add(:job_post, "paths are part of Pro after your first one") unless user.nil? || user.can_plan_from_job_post?
    end
end
