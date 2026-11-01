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

  test "a job post is scrubbed of contact details before it is stored" do
    goal = build_goal(job_post: "  Rails developer. Apply: hr@acme.in, +91 98765 43210  ")
    goal.save!

    assert_equal "Rails developer. Apply: [email removed], [phone removed]", goal.reload.job_post
  end

  test "a job post is at most 6,000 characters and required on the job-post form" do
    assert_not build_goal(job_post: "x" * 6_001).valid?
    assert build_goal(job_post: "x" * 6_000).valid?
    assert_not build_goal(from_job_post: true, job_post: "  ").valid?
    assert build_goal(job_post: "").valid?
  end

  test "a target date is optional but must be two weeks to two years away" do
    travel_to Date.new(2026, 10, 31) do
      assert build_goal(target_date: nil).valid?
      assert_not build_goal(target_date: Date.new(2026, 11, 13)).valid?
      assert build_goal(target_date: Date.new(2026, 11, 14)).valid?
      assert_not build_goal(target_date: Date.new(2028, 11, 1)).valid?
    end
  end

  test "weeks and minutes until the target date" do
    goal = build_goal(hours_per_week: 5, target_date: Date.new(2026, 12, 1))

    assert_equal 5, goal.weeks_left(today: Date.new(2026, 10, 31))
    assert_equal 1_500, goal.minutes_until_target(today: Date.new(2026, 10, 31))
    assert_equal 1, goal.weeks_left(today: Date.new(2026, 12, 5)), "never less than a week"
    assert_nil build_goal.minutes_until_target
  end

  test "free users plan one path from a job post, then it is Pro" do
    user = users(:two)
    assert user.can_plan_from_job_post?

    build_goal(job_post: "First post").save!
    assert_not user.can_plan_from_job_post?

    second = build_goal(topic: "Golang", job_post: "Second post")
    assert_not second.valid?
    assert_includes second.errors[:job_post], "paths are part of Pro after your first one"
    assert build_goal(topic: "Rust basics").valid?, "topic paths are still fine"
  end

  test "Pro users plan from as many job posts as they like" do
    user = users(:two)
    build_goal(job_post: "First post").save!
    user.define_singleton_method(:pro?) { true }

    assert user.can_plan_from_job_post?
  end
end
