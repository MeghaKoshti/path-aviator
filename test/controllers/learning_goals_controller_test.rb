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

  test "the job post form asks for the post and a finish date" do
    sign_in_as users(:two)
    get new_learning_goal_path(from: "job_post")

    assert_response :success
    assert_select "nav[aria-label='How to plan'] a[aria-current=page]", "I have a job post"
    assert_select "input[type=hidden][name='learning_goal[from_job_post]'][value=true]"
    assert_select "label[for=learning_goal_topic]", "Job title"
    assert_select "textarea#learning_goal_job_post[maxlength='6000'][required]"
    assert_select "input#learning_goal_target_date[type=date]"
  end

  test "a path from a job post stores the scrubbed post and the target date" do
    sign_in_as users(:two)
    target = 5.weeks.from_now.to_date

    post learning_goals_path, params: goal_params(topic: "Junior Rails developer", from_job_post: "true", target_date: target.iso8601,
                                                  job_post: "Rails + Hotwire role. Email jobs@acme.in, call 98765 43210.")

    goal = users(:two).learning_goals.order(:id).last
    assert_redirected_to goal.learning_path
    assert_equal "Rails + Hotwire role. Email [email removed], call [phone removed].", goal.job_post
    assert_equal target, goal.target_date
  end

  test "an empty job post is sent back to the first step" do
    sign_in_as users(:two)

    post learning_goals_path, params: goal_params(from_job_post: "true", job_post: "")

    assert_response :unprocessable_entity
    assert_select "form[data-start-step='0']"
    assert_select "#learning_goal_job_post_error", /can't be blank/
  end

  test "after the first job-post path, free users see the Pro note instead of the form" do
    sign_in_as users(:two)
    users(:two).learning_goals.create!(topic: "Earlier job", current_level: :beginner, hours_per_week: 3, job_post: "Old post")

    get new_learning_goal_path(from: "job_post")
    assert_select "h2", "Planning from a job post is part of Pro"
    assert_select "form[action=?]", learning_goals_path, count: 0

    assert_no_difference -> { LearningGoal.count } do
      post learning_goals_path, params: goal_params(from_job_post: "true", job_post: "New post")
    end
    assert_response :unprocessable_entity
  end
end
