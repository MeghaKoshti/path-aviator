require "test_helper"

class LearningGoalTest < ActiveSupport::TestCase
  def build_goal(**attrs)
    users(:two).learning_goals.new({ topic: "TypeScript", current_level: :beginner, hours_per_week: 5 }.merge(attrs))
  end

  test "fixture goals are valid" do
    assert learning_goals(:rails).valid?
    assert learning_goals(:sql).valid?
  end

  test "valid without a goal description" do
    assert build_goal(goal_description: nil).valid?
  end

  test "topic must be 3 to 100 characters" do
    assert_not build_goal(topic: "Go").valid?
    assert_not build_goal(topic: "x" * 101).valid?
    assert build_goal(topic: "x" * 100).valid?
  end

  test "topic whitespace is squished" do
    assert_equal "Machine learning", build_goal(topic: "  Machine   learning ").topic
  end

  test "hours per week must be a whole number between 1 and 40" do
    assert_not build_goal(hours_per_week: 0).valid?
    assert_not build_goal(hours_per_week: 41).valid?
    assert_not build_goal(hours_per_week: 2.5).valid?
    assert_not build_goal(hours_per_week: nil).valid?
    assert build_goal(hours_per_week: 40).valid?
  end

  test "an out-of-range hours error reads like a sentence" do
    goal = build_goal(hours_per_week: 41)
    goal.validate
    assert_equal [ "Hours per week must be between 1 and 40" ], goal.errors.full_messages_for(:hours_per_week)
  end

  test "goal description is limited to 500 characters" do
    assert_not build_goal(goal_description: "a" * 501).valid?
    assert build_goal(goal_description: "a" * 500).valid?
  end

  test "rejects an unknown level instead of raising" do
    goal = build_goal(current_level: "expert")
    assert_not goal.valid?
    assert goal.errors.of_kind?(:current_level, :inclusion)
  end

  test "level enum exposes predicates" do
    assert learning_goals(:sql).intermediate?
  end

  test "a user is onboarded once they have a goal" do
    user = User.create!(email_address: "new@example.com", password: "password123")
    assert_not user.onboarded?

    user.learning_goals.create!(topic: "Elixir", current_level: :beginner, hours_per_week: 4)
    assert user.onboarded?
  end

  test "destroying a user removes their goals" do
    assert_difference("LearningGoal.count", -2) { users(:one).destroy }
  end
end
