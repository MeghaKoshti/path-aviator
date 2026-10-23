class LearningGoal < ApplicationRecord
  belongs_to :user

  enum :current_level, { beginner: 0, intermediate: 1, advanced: 2 }, validate: true

  normalizes :topic, with: ->(topic) { topic.squish }
  normalizes :goal_description, with: ->(text) { text.strip.presence }

  validates :topic, presence: true, length: { in: 3..100 }
  validates :hours_per_week, presence: true,
                             numericality: { only_integer: true, in: 1..40 }
  validates :goal_description, length: { maximum: 500 }
end
