require "test_helper"

class LearningStatsTest < ActiveSupport::TestCase
  # Friday 23 October 2026, mid-afternoon in Kolkata.
  NOW = Time.utc(2026, 10, 23, 10, 0)
  ZONE = ActiveSupport::TimeZone["Asia/Kolkata"]

  setup do
    @user = User.create!(email_address: "stats@example.com", password: "long-enough-pw")
    goal = @user.learning_goals.create!(topic: "Elixir", current_level: :beginner, hours_per_week: 4)
    @user.learning_goals.create!(topic: "Go basics", current_level: :beginner, hours_per_week: 2)
    @path = goal.create_learning_path!(user: @user, title: "Elixir", status: :ready)
    @position = 0
  end

  def finish_step(at:, minutes: 30)
    @position += 1
    @path.path_steps.create!(position: @position, title: "Step #{@position}", resource_type: "docs",
                             resource_url: "https://example.com/#{@position}", estimated_minutes: minutes, completed_at: at)
  end

  def stats(now: NOW, zone: ZONE)
    LearningStats.new(@user, time_zone: zone, now: now)
  end

  def local(*args)
    ZONE.local(*args)
  end

  test "a user with no finished steps has empty stats and the goal of their biggest goal" do
    finish_step(at: nil)

    s = stats
    assert s.empty?
    assert_equal 0, s.minutes_this_week
    assert_equal 0, s.streak
    assert_equal 240, s.weekly_goal_minutes
    assert_equal 0, s.goal_percent
    assert_not s.goal_reached?
    assert_equal 7, s.week.size
    assert s.week.none?(&:active)
  end

  test "a user with no goals has no weekly goal" do
    user = User.create!(email_address: "new@example.com", password: "long-enough-pw")

    s = LearningStats.new(user, time_zone: ZONE, now: NOW)
    assert_equal 0, s.weekly_goal_minutes
    assert_equal 0, s.goal_percent
    assert_not s.goal_reached?
  end

  test "the week starts on Monday at midnight in the user's time zone" do
    finish_step(at: local(2026, 10, 19, 0, 0), minutes: 45)   # Monday 00:00, counts
    finish_step(at: local(2026, 10, 18, 23, 59), minutes: 60) # Sunday night, last week
    finish_step(at: local(2026, 10, 23, 9, 0), minutes: 30)   # today

    s = stats
    assert_equal Date.new(2026, 10, 19), s.week_start
    assert_equal 75, s.minutes_this_week
    assert_equal 31, s.goal_percent
    assert_equal [ true, false, false, false, true, false, false ], s.week.map(&:active)
    assert_equal Date.new(2026, 10, 23), s.week.find(&:today).date
    assert_equal 2, s.week.count(&:future)
  end

  test "the same moment can fall in different weeks in different zones" do
    # Monday 19 Oct, 02:00 in Kolkata is still Sunday evening in UTC.
    finish_step(at: local(2026, 10, 19, 2, 0), minutes: 45)

    assert_equal 45, stats(zone: ZONE).minutes_this_week
    assert_equal 0, stats(zone: ActiveSupport::TimeZone["UTC"]).minutes_this_week
  end

  test "on a Monday only that day counts" do
    finish_step(at: local(2026, 10, 18, 20, 0), minutes: 60)
    finish_step(at: local(2026, 10, 19, 8, 0), minutes: 20)

    assert_equal 20, stats(now: local(2026, 10, 19, 9, 0)).minutes_this_week
  end

  test "the goal is reached at 100 percent and capped there" do
    finish_step(at: local(2026, 10, 20, 9, 0), minutes: 300)

    assert stats.goal_reached?
    assert_equal 100, stats.goal_percent
  end

  test "a streak counts back from today" do
    [ 23, 22, 21 ].each { |day| finish_step(at: local(2026, 10, day, 8, 0)) }
    finish_step(at: local(2026, 10, 19, 8, 0)) # gap on the 20th

    assert_equal 3, stats.streak
    assert stats.active_today?
  end

  test "a streak that ended yesterday still counts until today is over" do
    [ 22, 21 ].each { |day| finish_step(at: local(2026, 10, day, 23, 30)) }

    assert_equal 2, stats.streak
    assert_not stats.active_today?
  end

  test "a streak is broken by a missed day" do
    finish_step(at: local(2026, 10, 21, 8, 0))

    assert_equal 0, stats.streak
  end

  test "several steps on one day count as one streak day, and streaks can cross weeks and months" do
    3.times { finish_step(at: local(2026, 10, 23, 8, 0)) }
    (Date.new(2026, 9, 28)..Date.new(2026, 10, 22)).each { |date| finish_step(at: local(date.year, date.month, date.day, 12, 0)) }

    assert_equal 26, stats.streak
  end

  test "other users' steps and unfinished steps don't count" do
    finish_step(at: nil, minutes: 90)
    path_steps(:rails_intro).update!(completed_at: local(2026, 10, 23, 8, 0))

    assert_equal 0, stats.minutes_this_week
    assert_equal 0, stats.streak
  end

  test "uses two queries however many steps are done" do
    5.times { |i| finish_step(at: local(2026, 10, 23 - i, 8, 0)) }

    queries = 0
    counter = ->(*, payload) { queries += 1 unless payload[:name].in?([ "SCHEMA", "TRANSACTION" ]) }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      s = stats
      s.minutes_this_week
      s.streak
      s.week
      s.goal_percent
      s.empty?
    end
    assert_equal 2, queries
  end
end
