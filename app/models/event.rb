# First-party product analytics: a row per activation milestone, so the
# owner can see the funnel without any third-party script.
#
#   Event.track(:path_ready, user: user, path_id: 7)
#   Event.track_once(:first_step_done, user: user)
class Event < ApplicationRecord
  NAMES = %w[signed_up path_ready path_failed first_step_done returned_week_2 upgraded].freeze

  belongs_to :user, optional: true

  validates :name, inclusion: { in: NAMES }

  scope :named, ->(name) { where(name: name.to_s) }
  scope :since, ->(time) { where(created_at: time..) }

  # Tracking must never break what the user is doing, so failures are only reported.
  def self.track(name, user: nil, **properties)
    create!(name: name.to_s, user: user, properties: properties)
  rescue ActiveRecord::ActiveRecordError => e
    Rails.error.report(e, handled: true, context: { event: name })
    nil
  end

  # For milestones that happen once per user (first step, week-2 return).
  def self.track_once(name, user:, **properties)
    track(name, user: user, **properties) unless named(name).exists?(user: user)
  end
end
