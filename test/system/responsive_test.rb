require "application_system_test_case"

class ResponsiveTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(email_address: "long@example.com", password: "long-enough-pw")
    # One unbroken 100-character topic, the longest the form allows.
    goal = @user.learning_goals.create!(topic: "Kubernetes" * 10, current_level: :beginner, hours_per_week: 5)
    @path = goal.create_learning_path!(user: @user)
    GenerateLearningPathJob.perform_now(@path)
  end

  teardown do
    page.current_window.resize_to(1400, 1400)
  end

  test "a topic that is one long word doesn't make a phone screen scroll sideways" do
    page.current_window.resize_to(375, 800)
    sign_in_through_ui @user, password: "long-enough-pw"

    visit dashboard_path
    assert_selector "##{dom_id(@path, :card)}"
    assert_no_horizontal_scroll

    visit learning_path_path(@path)
    assert_selector "##{dom_id(@path, :progress)}"
    assert_no_horizontal_scroll
  end

  test "public pages fit a phone screen" do
    page.current_window.resize_to(375, 800)

    [ root_path, pricing_path, privacy_path, learn_topics_path, learn_topic_path(LearnTopic.all.first) ].each do |path|
      visit path
      assert_selector "h1"
      assert_no_horizontal_scroll
    end
  end

  private
    def assert_no_horizontal_scroll
      overflow = evaluate_script("document.documentElement.scrollWidth - document.documentElement.clientWidth")
      assert_operator overflow, :<=, 0, "#{current_path} scrolls sideways by #{overflow}px"
    end
end
