class LearningPath < ApplicationRecord
  belongs_to :user
  belongs_to :learning_goal
  has_many :path_steps, -> { order(:position) }, dependent: :destroy, inverse_of: :learning_path

  enum :status, { generating: 0, ready: 1, failed: 2 }, default: :generating

  validates :title, presence: true, if: :ready?
  validates :learning_goal_id, uniqueness: true
  validate :goal_belongs_to_user

  def progress_percent
    return 0 if path_steps_count.zero?

    (completed_steps_count * 100.0 / path_steps_count).round.clamp(0, 100)
  end

  # Uses already-loaded steps when available so list pages don't run a query per path.
  def remaining_minutes
    if path_steps.loaded?
      path_steps.reject(&:completed?).sum(&:estimated_minutes)
    else
      path_steps.incomplete.sum(:estimated_minutes)
    end
  end

  def next_step
    path_steps.loaded? ? path_steps.find { |step| !step.completed? } : path_steps.incomplete.first
  end

  def completed?
    ready? && path_steps_count.positive? && completed_steps_count >= path_steps_count
  end

  # Sharing gives the path a read-only public page at /p/:token. A token means
  # shared, nil means private. (has_secure_token would fill one in for every
  # new path, sharing them all by default, so the same generator is used here.)
  def shared?
    share_token.present?
  end

  # Turns sharing on, or swaps in a new link so the old one stops working.
  def share!
    update!(share_token: self.class.generate_unique_secure_token)
  end

  def unshare!
    update!(share_token: nil)
  end

  def owner_first_name
    user.name.to_s.split.first
  end

  # Throws away the current steps (and progress) and asks the generator again.
  def regenerate!
    transaction do
      path_steps.delete_all
      update!(status: :generating, completed_steps_count: 0, error_message: nil, raw_response: nil, generated_at: nil)
    end
    reload
    GenerateLearningPathJob.perform_later(self)
  end

  # Both the path page and the dashboard listen on this stream; each page only
  # has one of the two targets, so the other replace is ignored there.
  def broadcast_refresh
    broadcast_replace_to [ user, :learning_paths ],
      target: ActionView::RecordIdentifier.dom_id(self),
      partial: "learning_paths/learning_path",
      locals: { learning_path: self }
    broadcast_replace_to [ user, :learning_paths ],
      target: ActionView::RecordIdentifier.dom_id(self, :card),
      partial: "learning_paths/card",
      locals: { learning_path: self }
  end

  private
    def goal_belongs_to_user
      return if learning_goal.nil? || learning_goal.user_id == user_id

      errors.add(:learning_goal, "must belong to the same user")
    end
end
