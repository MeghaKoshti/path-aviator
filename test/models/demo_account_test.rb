require "test_helper"
require "minitest/mock"

class DemoAccountTest < ActiveSupport::TestCase
  test "reset! puts back the sign-in details and removes what visitors added" do
    user = DemoAccount.reset!
    user.update_columns(name: "Hacked")
    goal = user.learning_goals.create!(topic: "Kubernetes", current_level: :beginner, hours_per_week: 2)
    LearningPath.create!(user: user, learning_goal: goal)
    rails_path = user.learning_paths.find_by!(title: DemoAccount::PATHS.first.dig(:path, :title))
    rails_path.path_steps.create!(position: 9, title: "Extra", resource_type: "docs", resource_url: "https://example.com", estimated_minutes: 5)

    assert_difference -> { LearningGoal.count } => -1, -> { LearningPath.count } => -1, -> { PathStep.count } => -1 do
      assert_equal user, DemoAccount.reset!
    end

    user.reload
    assert_equal "Demo Learner", user.name
    assert user.authenticate(DemoAccount::PASSWORD)
    assert_equal [ "Git and GitHub", "Ruby on Rails" ], user.learning_goals.pluck(:topic).sort
    assert_equal [ 8, 3 ], rails_path.reload.then { [ _1.path_steps_count, _1.completed_steps_count ] }
  end

  test "reset! brings back a path a visitor regenerated" do
    rails_path = DemoAccount.reset!.learning_paths.order(:id).first
    rails_path.regenerate!

    DemoAccount.reset!

    rails_path.reload
    assert rails_path.ready?
    assert_equal [ 8, 8, 3 ], [ rails_path.path_steps.count, rails_path.path_steps_count, rails_path.completed_steps_count ]
  end

  test "is only enabled in production with SEED_DEMO=1" do
    old = ENV["SEED_DEMO"]
    ENV["SEED_DEMO"] = nil
    assert DemoAccount.enabled?

    Rails.stub(:env, ActiveSupport::EnvironmentInquirer.new("production")) do
      assert_not DemoAccount.enabled?
      ENV["SEED_DEMO"] = "1"
      assert DemoAccount.enabled?
    end
  ensure
    ENV["SEED_DEMO"] = old
  end
end
