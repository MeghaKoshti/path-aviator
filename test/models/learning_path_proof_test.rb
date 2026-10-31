require "test_helper"

class LearningPathProofTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @path = learning_paths(:rails)
    @path.path_steps.first.update!(evidence_url: "https://github.com/riya/blog")
  end

  def finish(path)
    path.path_steps.each { |step| step.update!(completed_at: 1.hour.ago) unless step.completed? }
    path.reload
  end

  test "copy_for gives another user the same plan with no progress, notes or evidence" do
    copy = assert_difference -> { users(:two).learning_paths.count } => 1, -> { PathStep.count } => 4 do
      @path.copy_for(users(:two))
    end

    assert copy.ready?
    assert_equal users(:two), copy.user
    assert_equal users(:two), copy.learning_goal.user
    assert_equal [ "Ruby on Rails", "beginner", 6 ], copy.learning_goal.values_at(:topic, :current_level, :hours_per_week)
    assert_nil copy.learning_goal.goal_description, "the goal text is private"
    assert_equal @path.title, copy.title
    assert_equal @path.path_steps.map { |s| [ s.position, s.title, s.resource_url, s.estimated_minutes ] },
                 copy.path_steps.map { |s| [ s.position, s.title, s.resource_url, s.estimated_minutes ] }
    assert copy.path_steps.none?(&:completed?)
    assert copy.path_steps.all? { |s| s.note.nil? && s.evidence_url.nil? }
    assert_equal 0, copy.completed_steps_count
    assert_not copy.shared?
    assert_equal 1, @path.reload.completed_steps_count, "the original is untouched"
  end

  test "copying doesn't ask the AI for a new plan" do
    assert_no_enqueued_jobs { @path.copy_for(users(:two)) }
  end

  test "only a finished path can publish a certificate, and publishing again keeps the link" do
    assert_raises(ArgumentError) { @path.publish_certificate! }

    finish(@path).publish_certificate!
    token = @path.certificate_token
    assert @path.certificate_published?
    assert_not_nil @path.certificate_issued_at

    @path.publish_certificate!
    assert_equal token, @path.certificate_token

    @path.revoke_certificate!
    assert_not @path.certificate_published?
  end

  test "dates and totals for the certificate" do
    finish(@path)

    assert_equal 315, @path.total_minutes
    assert_equal @path.path_steps.map(&:completed_at).max, @path.finished_at
    assert_operator @path.started_at, :<=, @path.created_at
  end

  test "evidence links must be http(s) and blank clears them" do
    step = path_steps(:rails_models)

    step.evidence_url = "javascript:alert(1)"
    assert_not step.valid?
    assert_includes step.errors[:evidence_url], "must be a link starting with http:// or https://"

    step.update!(evidence_url: "  ")
    assert_nil step.evidence_url
  end
end
