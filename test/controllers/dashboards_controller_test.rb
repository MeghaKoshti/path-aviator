require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  test "requires sign-in" do
    get dashboard_path
    assert_redirected_to new_session_path
  end

  test "signed-in app shell has the main navigation and account menu" do
    sign_in_as users(:one)

    get dashboard_path

    assert_response :success
    assert_select "nav[aria-label=Main] a[href=?][aria-current=page]", dashboard_path, text: "Dashboard"
    assert_select "nav[aria-label=Main] a[href=?]", new_learning_goal_path, text: "New path"
    assert_select "#account-menu a[href=?]", settings_path, text: "Settings"
    assert_select "#account-menu form[action=?] button", session_path, text: "Sign out"
    assert_select "button[aria-controls=mobile-menu][aria-expanded=false]"
    assert_select "a[href='#main']", "Skip to main content"
  end

  test "lists only the signed-in user's paths with progress and a way to continue" do
    sign_in_as users(:one)
    rails = learning_paths(:rails)

    get dashboard_path

    assert_select "turbo-cable-stream-source[signed-stream-name=?]", Turbo::StreamsChannel.signed_stream_name([ users(:one), :learning_paths ])
    assert_select "article[id^=card_learning_path_]", 2
    assert_select "##{dom_id(learning_paths(:docker), :card)}", false
    assert_select "##{dom_id(rails, :card)}" do
      assert_select "h2 a[href=?]", learning_path_path(rails), text: rails.title
      assert_select "dd", "25%"
      assert_select "[role=img][aria-label='1 of 4 steps done']"
      assert_select "a[href=?]", learning_path_path(rails, anchor: dom_id(path_steps(:rails_models))), text: /Continue/
    end
    assert_select "##{dom_id(learning_paths(:sql), :card)}", text: /Planning/
    assert_select "a[href=?]", new_learning_goal_path, text: "Start another path"
  end

  test "shows an empty state when there are no paths yet" do
    sign_in_as users(:two)
    users(:two).learning_paths.destroy_all

    get dashboard_path

    assert_select "h2", "No paths yet"
    assert_select "a[href=?]", new_learning_goal_path, text: "Plan your first path"
  end

  test "the number of queries doesn't grow with the number of paths" do
    sign_in_as users(:one)
    before = count_queries { get dashboard_path }

    3.times { |i| create_ready_path(users(:one), "Topic #{i}") }
    after = count_queries { get dashboard_path }

    assert_equal before, after
  end

  private
    def count_queries(&block)
      count = 0
      counter = ->(*, payload) { count += 1 unless payload[:name].in?([ "SCHEMA", "TRANSACTION" ]) || payload[:cached] }
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
      count
    end

    def create_ready_path(user, topic)
      goal = user.learning_goals.create!(topic: topic, current_level: :beginner, hours_per_week: 3)
      path = goal.create_learning_path!(user: user, title: "#{topic} path", status: :ready)
      2.times do |i|
        path.path_steps.create!(position: i + 1, title: "Step #{i + 1}", resource_type: "docs",
                                resource_url: "https://example.com/#{i}", estimated_minutes: 30)
      end
    end
end
