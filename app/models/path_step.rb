class PathStep < ApplicationRecord
  RESOURCE_TYPES = %w[video article docs course practice].freeze
  NOTE_MAX_LENGTH = 2_000

  belongs_to :learning_path, counter_cache: true

  scope :ordered, -> { order(:position) }
  scope :incomplete, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :owned_by, ->(user) { joins(:learning_path).where(learning_paths: { user_id: user.id }) }

  # A blank note is stored as nil, so saving an empty box removes the note.
  normalizes :note, with: ->(note) { note.strip.presence }

  validates :title, presence: true
  validates :position, numericality: { only_integer: true, greater_than: 0 },
                       uniqueness: { scope: :learning_path_id }
  validates :resource_type, inclusion: { in: RESOURCE_TYPES }
  validates :estimated_minutes, numericality: { only_integer: true, greater_than: 0 }
  validates :note, length: { maximum: NOTE_MAX_LENGTH }
  validate :resource_url_must_be_http

  # completed_steps_count is kept in sync by these callbacks, which run inside
  # the same transaction as the step's own save or destroy.
  after_create :adjust_completed_count, if: :completed?
  after_update :adjust_completed_count, if: :completion_changed?
  after_destroy :adjust_completed_count, if: -> { completed? && !destroyed_by_association }

  def self.http_url?(value)
    uri = URI.parse(value.to_s)
    uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    false
  end

  def completed?
    completed_at.present?
  end

  def toggle_completion!
    with_lock do
      update!(completed_at: completed? ? nil : Time.current)
    end
  end

  private
    def completion_changed?
      saved_change_to_completed_at? && completed_at_before_last_save.nil? != completed_at.nil?
    end

    def adjust_completed_count
      delta = completed? && !destroyed? ? 1 : -1
      learning_path.increment!(:completed_steps_count, delta, touch: true)
    end

    def resource_url_must_be_http
      errors.add(:resource_url, "must be an http or https link") unless self.class.http_url?(resource_url)
    end
end
