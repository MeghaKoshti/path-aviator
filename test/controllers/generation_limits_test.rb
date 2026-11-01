require "test_helper"

# The quota, the global cap and the rate limit in front of every AI generation.
class GenerationLimitsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  def goal_params
    { learning_goal: { topic: "Kubernetes", current_level: "beginner", hours_per_week: 4 } }
  end

  def use_up_quota(user = @user)
    user.generation_quota.limit.times { user.generations.create! }
  end

  test "planning a path records a generation linked to it" do
    assert_difference "@user.generations.count", 1 do
      post learning_goals_path, params: goal_params
    end

    assert_equal LearningPath.order(:id).last, @user.generations.last.learning_path
    assert_equal 2, @user.generations_left_this_month
  end

  test "invalid answers don't use up a generation" do
    assert_no_difference "Generation.count" do
      post learning_goals_path, params: { learning_goal: { topic: "Go", current_level: "beginner", hours_per_week: 4 } }
    end
  end

  test "with the free paths used up, the new-path page offers Pro instead of the form" do
    use_up_quota

    get new_learning_goal_path

    assert_response :success
    assert_select "form[action=?]", learning_goals_path, count: 0
    assert_select "[data-upgrade-reason=limit]" do
      assert_select "h2", "You’ve used this month’s free paths"
      assert_select "a", "Upgrade to Pro"
    end
  end

  test "with the free paths used up, creating a path is refused and nothing is queued" do
    use_up_quota

    assert_no_difference [ "LearningGoal.count", "LearningPath.count", "Generation.count" ] do
      post learning_goals_path, params: goal_params
    end

    assert_response :forbidden
    assert_select "[data-upgrade-reason=limit] p", /used your 3 free paths this month/
    assert_no_enqueued_jobs
  end

  test "pro users can keep going past three" do
    @user.update!(plan: :pro)
    3.times { @user.generations.create! }

    assert_enqueued_jobs 1, only: GenerateLearningPathJob do
      post learning_goals_path, params: goal_params
    end
  end

  test "when the global daily cap is reached, generation fails fast with a busy message and a log line" do
    with_env("AI_DAILY_GENERATION_LIMIT" => "1") do
      users(:two).generations.create!

      log = StringIO.new
      original_logger = Rails.logger
      Rails.logger = ActiveSupport::Logger.new(log)
      begin
        post learning_goals_path, params: goal_params
      ensure
        Rails.logger = original_logger
      end

      assert_response :forbidden
      assert_select "[role=alert]", /very busy right now/
      assert_match "[AI cost guard] daily limit of 1 generations reached", log.string
      assert_no_enqueued_jobs
    end
  end

  test "regenerating counts as a generation" do
    path = learning_paths(:rails)

    assert_difference "@user.generations.count", 1 do
      post regenerate_learning_path_path(path)
    end
    assert_equal path, @user.generations.last.learning_path
  end

  test "regenerating with the quota used up is refused with a message" do
    use_up_quota
    path = learning_paths(:rails)

    assert_no_enqueued_jobs do
      post regenerate_learning_path_path(path)
    end

    assert_redirected_to learning_path_path(path)
    assert_match "Upgrade to Pro", flash[:alert]
    assert path.reload.ready?
  end

  test "the path page swaps Regenerate for an upgrade prompt when the quota is used up" do
    use_up_quota

    get learning_path_path(learning_paths(:rails))

    assert_select "form[action=?]", regenerate_learning_path_path(learning_paths(:rails)), count: 0
    assert_select "[data-upgrade-reason=limit] a", "Upgrade to Pro"
  end

  test "creating paths is rate limited per user" do
    @user.update!(plan: :pro)

    5.times { post learning_goals_path, params: goal_params }
    assert_no_difference "LearningPath.count" do
      post learning_goals_path, params: goal_params
    end

    assert_redirected_to new_learning_goal_path
    assert_match "very quickly", flash[:alert]
  end

  test "the demo account is exempt from the monthly quota" do
    demo = DemoAccount.reset!
    sign_in_as demo, password: DemoAccount::PASSWORD
    use_up_quota(demo)

    assert_enqueued_jobs 1, only: GenerateLearningPathJob do
      post learning_goals_path, params: goal_params
    end
  end
end
