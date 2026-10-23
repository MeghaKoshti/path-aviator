require "test_helper"
require "minitest/mock"

class SeedsTest < ActiveSupport::TestCase
  def demo_user
    User.find_by!(email_address: "demo@pathaviator.dev")
  end

  def seed_in_production(seed_demo:)
    old = ENV["SEED_DEMO"]
    ENV["SEED_DEMO"] = seed_demo
    Rails.stub(:env, ActiveSupport::EnvironmentInquirer.new("production")) { Rails.application.load_seed }
  ensure
    ENV["SEED_DEMO"] = old
  end

  test "creates the demo account with an in-progress and a completed path" do
    Rails.application.load_seed

    user = demo_user
    assert user.authenticate("pathaviator-demo")
    assert user.onboarded?

    in_progress, completed = user.learning_paths.order(:id).to_a
    assert in_progress.ready?
    assert_equal [ 8, 3 ], [ in_progress.path_steps_count, in_progress.completed_steps_count ]
    assert_equal 38, in_progress.progress_percent
    assert_not in_progress.completed?

    assert completed.completed?
    assert_equal 100, completed.progress_percent
  end

  test "the demo has notes, a live streak and one shared path" do
    Rails.application.load_seed

    user = demo_user
    in_progress, completed = user.learning_paths.order(:id).to_a
    assert_equal 2, in_progress.path_steps.where.not(note: nil).count
    assert in_progress.shared?
    assert_not completed.shared?

    stats = LearningStats.new(user)
    assert_equal 3, stats.streak
    assert stats.active_today?
    assert_equal 360, stats.weekly_goal_minutes
  end

  test "seeding twice does not duplicate anything" do
    Rails.application.load_seed
    counts = -> { [ User.count, LearningGoal.count, LearningPath.count, PathStep.count ] }

    token = demo_user.learning_paths.order(:id).first.share_token

    assert_no_changes(counts) { Rails.application.load_seed }
    assert_equal token, demo_user.learning_paths.order(:id).first.share_token, "the demo share link should keep working"
    assert_equal [ 8, 3 ], demo_user.learning_paths.order(:id).first.then { [ _1.path_steps_count, _1.completed_steps_count ] }
  end

  test "in production the demo account is only seeded with SEED_DEMO=1" do
    assert_output(/SEED_DEMO=1/) { seed_in_production(seed_demo: nil) }
    assert_output(/SEED_DEMO=1/) { seed_in_production(seed_demo: "0") }
    assert_not User.exists?(email_address: "demo@pathaviator.dev")

    seed_in_production(seed_demo: "1")
    assert demo_user.authenticate("pathaviator-demo")
  end

  test "re-seeding resets demo progress, notes and sharing" do
    Rails.application.load_seed
    path = demo_user.learning_paths.order(:id).first
    path.path_steps.incomplete.first.toggle_completion!
    path.path_steps.first.update!(note: "Scribble")
    path.unshare!

    Rails.application.load_seed

    assert_equal 3, path.reload.completed_steps_count
    assert_equal 3, path.path_steps.completed.count
    assert_nil path.path_steps.first.note
    assert path.shared?
  end
end
