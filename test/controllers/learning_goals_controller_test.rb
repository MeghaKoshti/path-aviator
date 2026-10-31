require "test_helper"

class LearningGoalsControllerTest < ActionDispatch::IntegrationTest
  def goal_params(**overrides)
    { learning_goal: { topic: "Kubernetes", current_level: "intermediate", hours_per_week: 4, goal_description: "Run my side project on a cluster." }.merge(overrides) }
  end

  test "requires sign-in" do
    get new_learning_goal_path
    assert_redirected_to new_session_path
  end

  test "first-time users get a welcome and all three steps" do
    user = User.create!(name: "Asha Rao", email_address: "asha@example.com", password: "long-enough-pw")
    sign_in_as user, password: "long-enough-pw"

    get new_learning_goal_path

    assert_response :success
    assert_select "h1", "Welcome, Asha. Where to first?"
    assert_select "turbo-frame#onboarding[data-controller=onboarding] form[action=?]", learning_goals_path
    assert_select "fieldset[data-onboarding-target=step]", 3
    assert_select "label[for=learning_goal_topic]", "Topic"
    assert_select "input[type=radio][name='learning_goal[current_level]']", 3
    assert_select "input#learning_goal_hours_per_week[type=number][min='1'][max='40']"
    assert_select "textarea#learning_goal_goal_description[maxlength='500']"
  end

  test "people with paths see the new-path heading" do
    sign_in_as users(:one)

    get new_learning_goal_path

    assert_select "h1", "Plan a new path"
  end

  test "creating a goal plans a path, queues generation and opens the path" do
    sign_in_as users(:one)

    assert_difference [ "LearningGoal.count", "LearningPath.count" ], 1 do
      assert_enqueued_jobs 1, only: GenerateLearningPathJob do
        post learning_goals_path, params: goal_params
      end
    end

    path = LearningPath.order(:id).last
    assert_redirected_to learning_path_path(path)
    assert path.generating?
    assert_equal users(:one), path.user
    assert_equal "Kubernetes", path.learning_goal.topic
    assert_enqueued_with job: GenerateLearningPathJob, args: [ path ]
  end

  test "invalid answers re-render inline errors and open the step that needs fixing" do
    sign_in_as users(:one)

    assert_no_difference [ "LearningGoal.count", "LearningPath.count" ] do
      post learning_goals_path, params: goal_params(hours_per_week: 0)
    end

    assert_response :unprocessable_entity
    assert_select "form[data-start-step='2']"
    assert_select "#learning_goal_hours_per_week_error", /must be between 1 and 40/
    assert_select "[role=alert]", /Check the highlighted answer/
    assert_no_enqueued_jobs
  end

  test "a too-short topic sends people back to the first step" do
    sign_in_as users(:one)

    post learning_goals_path, params: goal_params(topic: "Go")

    assert_response :unprocessable_entity
    assert_select "form[data-start-step='0']"
    assert_select "#learning_goal_topic_error", /too short/
  end

  test "an unknown level is rejected" do
    sign_in_as users(:one)

    post learning_goals_path, params: goal_params(current_level: "wizard")

    assert_response :unprocessable_entity
    assert_select "form[data-start-step='1']"
    assert_select "#current_level_error"
  end
end
