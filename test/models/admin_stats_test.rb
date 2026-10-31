require "test_helper"

class AdminStatsTest < ActiveSupport::TestCase
  test "counts paths by status, every status listed" do
    assert_equal({ "generating" => 1, "ready" => 1, "failed" => 1 }, AdminStats.new.paths_by_status)
  end

  test "generations come from ready and failed events, today and this month" do
    now = Time.zone.local(2026, 10, 31, 12)
    Event.create!(name: "path_ready", created_at: now - 1.hour, properties: { estimated_tokens: 2_000_000 })
    Event.create!(name: "path_failed", created_at: now - 2.days)
    Event.create!(name: "path_ready", created_at: now - 40.days, properties: { estimated_tokens: 9_000_000 })

    stats = AdminStats.new(now: now)
    assert_equal 1, stats.generations_today
    assert_equal 2, stats.generations_this_month
    assert_equal 2_000_000, stats.estimated_tokens_this_month
    assert_equal 3.0, stats.estimated_cost_this_month_usd
  end

  test "the funnel counts people, not events, over 30 days" do
    2.times { Event.track(:first_step_done, user: users(:one)) }
    Event.track(:signed_up, user: users(:one))
    Event.track(:signed_up, user: users(:two))

    funnel = AdminStats.new.funnel
    assert_equal 2, funnel["signed_up"]
    assert_equal 1, funnel["first_step_done"]
    assert_equal 0, funnel["upgraded"]
  end

  test "billing columns are optional until that branch lands" do
    stats = AdminStats.new
    assert_equal User.column_names.include?("plan"), !stats.pro_users.nil?
    assert_equal User.column_names.include?("email_verified_at"), !stats.verified_users.nil?
  end
end
