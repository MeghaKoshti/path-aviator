require "application_system_test_case"

class OnboardingTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(name: "Asha Rao", email_address: "asha@example.com", password: "long-enough-pw")
  end

  test "new users answer three questions one at a time and land on their path" do
    sign_in_through_ui @user, password: "long-enough-pw"
    assert_selector "h1", text: "Welcome, Asha. Where to first?"
    assert_selector "[aria-live=polite]", text: "Step 1 of 3: Topic"

    # Step 1: the topic is required before moving on.
    assert_no_field "Hours per week"
    click_on "Ruby on Rails"
    click_on "Continue"

    # Step 2: level, then back and forward again keeps the answer.
    assert_selector "legend", text: "Where are you starting from?"
    assert_no_field "Topic"
    choose "Intermediate"
    click_on "Back"
    assert_field "Topic", with: "Ruby on Rails"
    click_on "Continue"
    assert_checked_field "Intermediate"
    click_on "Continue"

    # Step 3: time and an optional goal.
    fill_in "Hours per week", with: "6"
    fill_in "Your goal (optional)", with: "Ship a portfolio app"
    click_on "Plan my path"

    assert_current_path %r{\A/learning_paths/\d+\z}
    path = @user.learning_paths.sole
    assert_current_path learning_path_path(path)
    assert_equal "Ruby on Rails", path.learning_goal.topic
    assert path.learning_goal.intermediate?
  end

  test "pressing Enter on the first step moves to the next one" do
    sign_in_through_ui @user, password: "long-enough-pw"

    fill_in "Topic", with: "Docker\n"

    assert_selector "legend", text: "Where are you starting from?"
    assert_equal 0, LearningGoal.where(user: @user).count
  end

  test "server-side errors reopen the step with the problem" do
    sign_in_through_ui @user, password: "long-enough-pw"
    fill_in "Topic", with: "Docker"
    click_on "Continue"
    click_on "Continue"
    # Bypass the browser's own range check to reach the server validation.
    execute_script("document.getElementById('learning_goal_hours_per_week').removeAttribute('max')")
    fill_in "Hours per week", with: "60"
    click_on "Plan my path"

    assert_selector "#learning_goal_hours_per_week_error", text: "must be between 1 and 40"
    assert_selector "legend", text: "How much time can you give it?"
    assert_no_field "Topic"
  end

  test "planning a first path from a job post with a finish date" do
    sign_in_through_ui @user, password: "long-enough-pw"
    click_on "I have a job post"

    assert_selector "legend", text: "Which job are you preparing for?"
    fill_in "Job title", with: "Junior Rails developer"
    fill_in "The job post", with: "Acme hires a Rails developer: Ruby on Rails, PostgreSQL, Docker. Apply at jobs@acme.in or +91 98765 43210."
    click_on "Continue"
    choose "Beginner"
    click_on "Continue"
    fill_in "Hours per week", with: "6"
    execute_script("document.getElementById('learning_goal_target_date').value = '#{6.weeks.from_now.to_date.iso8601}'")
    click_on "Plan my path"

    assert_current_path %r{\A/learning_paths/\d+\z}
    path = @user.learning_paths.sole
    GenerateLearningPathJob.perform_now(path)
    visit learning_path_path(path)
    assert_selector "h2", text: "Skills this covers"
    assert_selector "li", text: "PostgreSQL"
    assert_text "On track"
    assert_text "Finish by #{I18n.l(6.weeks.from_now.to_date, format: "%-d %b %Y")}"
    assert_equal "Acme hires a Rails developer: Ruby on Rails, PostgreSQL, Docker. Apply at [email removed] or [phone removed].", path.learning_goal.job_post
  end
end
