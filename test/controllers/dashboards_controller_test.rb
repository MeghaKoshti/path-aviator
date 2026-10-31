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
    assert_select "li[id^=card_learning_path_]", 2
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

  test "shows this week's time against the weekly goal, the week and the streak" do
    sign_in_as users(:one)
    path_steps(:rails_intro).update!(completed_at: Time.current)

    get dashboard_path

    assert_select "section#learning_stats[aria-labelledby=learning_stats_heading]" do
      assert_select "h2", "This week"
      assert_select "p", "1 h 30 min"
      assert_select "p", text: /of your 6 h weekly goal/
      assert_select "svg[role=img][aria-label=?]", "25% of your weekly goal"
      assert_select "ol[aria-label='Days this week'] > li", 7
      assert_select "li .sr-only", text: /\(today\):\s+steps done/
      assert_select "p", text: /1\s+day in a row/
      assert_select "p", text: "You learned something today."
    end
  end

  test "this week's panel invites a first tick when nothing is done yet" do
    sign_in_as users(:one)
    path_steps(:rails_intro).update!(completed_at: nil)

    get dashboard_path

    assert_select "#learning_stats", text: /Tick a step when you finish it/
    assert_select "#learning_stats svg", false
  end

  test "no stats panel before the first path" do
    sign_in_as users(:two)
    users(:two).learning_paths.destroy_all

    get dashboard_path

    assert_select "#learning_stats", false
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

  test "free users see how many free paths are left this month and an upgrade button" do
    users(:one).generations.create!
    sign_in_as users(:one)

    get dashboard_path

    assert_select "#plan_usage" do
      assert_select "p", "2 of 3 free paths left this month"
      assert_select "a", "Upgrade to Pro"
    end
  end

  test "pro users see a Pro badge and no upgrade button" do
    users(:one).update!(plan: :pro)
    sign_in_as users(:one)

    get dashboard_path

    assert_select "#plan_usage" do
      assert_select "span", "Pro"
      assert_select "p", "30 of 30 paths left this month"
      assert_select "a", text: "Upgrade to Pro", count: 0
    end
  end

  test "the demo account has no quota box" do
    demo = DemoAccount.reset!
    sign_in_as demo, password: DemoAccount::PASSWORD

    get dashboard_path

    assert_select "#plan_usage", count: 0
  end
end
