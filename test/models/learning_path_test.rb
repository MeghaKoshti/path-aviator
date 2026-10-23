require "test_helper"
# turbo-rails only auto-includes this when Action Cable is already loaded.
require "turbo/broadcastable/test_helper"

class LearningPathTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  setup do
    @path = learning_paths(:rails)
  end

  test "new paths start out generating" do
    assert LearningPath.new.generating?
  end

  test "fixture counters match the fixture steps" do
    assert_equal @path.path_steps.count, @path.path_steps_count
    assert_equal @path.path_steps.completed.count, @path.completed_steps_count
  end

  test "steps come back ordered by position" do
    assert_equal [ 1, 2, 3, 4 ], @path.path_steps.map(&:position)
  end

  test "progress percent is rounded and 0 without steps" do
    assert_equal 25, @path.progress_percent
    assert_equal 0, learning_paths(:sql).progress_percent

    @path.completed_steps_count = 1
    @path.path_steps_count = 3
    assert_equal 33, @path.progress_percent
  end

  test "remaining minutes sums incomplete steps, with or without preloading" do
    assert_equal 60 + 45 + 120, @path.remaining_minutes
    assert_equal 225, LearningPath.includes(:path_steps).find(@path.id).remaining_minutes
  end

  test "next step is the first incomplete step by position" do
    assert_equal path_steps(:rails_models), @path.next_step
    assert_equal path_steps(:rails_models), LearningPath.includes(:path_steps).find(@path.id).next_step
  end

  test "completed only when ready and every step is done" do
    assert_not @path.completed?

    @path.path_steps.incomplete.each(&:toggle_completion!)
    assert @path.reload.completed?
    assert_nil @path.next_step
    assert_equal 100, @path.progress_percent
    assert_equal 0, @path.remaining_minutes
  end

  test "a path with no steps is never completed" do
    assert_not learning_paths(:sql).completed?
  end

  test "ready paths need a title" do
    path = learning_paths(:sql)
    path.status = :ready
    assert_not path.valid?
    assert path.errors.of_kind?(:title, :blank)
  end

  test "goal must belong to the same user" do
    path = users(:two).learning_paths.new(learning_goal: learning_goals(:rails))
    assert_not path.valid?
    assert_includes path.errors[:learning_goal], "must belong to the same user"
  end

  test "a goal can only have one path" do
    path = users(:one).learning_paths.new(learning_goal: learning_goals(:rails))
    assert_not path.valid?
    assert path.errors.of_kind?(:learning_goal_id, :taken)
  end

  test "destroying the goal destroys its path and steps" do
    assert_difference -> { LearningPath.count } => -1, -> { PathStep.count } => -4 do
      learning_goals(:rails).destroy
    end
  end

  test "destroying a user removes paths, steps and goals" do
    assert_difference -> { LearningPath.count } => -2, -> { LearningGoal.count } => -2 do
      users(:one).destroy
    end
  end

  test "broadcast_refresh replaces the path card on the user's stream" do
    streams = capture_turbo_stream_broadcasts([ @path.user, :learning_paths ]) { @path.broadcast_refresh }

    assert_equal 1, streams.size
    assert_equal "replace", streams.first["action"]
    assert_equal ActionView::RecordIdentifier.dom_id(@path), streams.first["target"]
    assert_includes streams.first.to_html, @path.title
  end
end
