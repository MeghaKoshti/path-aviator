require "test_helper"

class GenerationQuotaTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
  end

  def generate!(at:, user: @user, path: nil)
    user.generations.create!(learning_path: path, created_at: at)
  end

  test "a free user gets three generations a calendar month" do
    travel_to Time.utc(2026, 10, 20, 12) do
      assert_equal 3, @user.generations_left_this_month

      generate!(at: 2.days.ago)
      generate!(at: 1.hour.ago)
      assert_equal 1, @user.generations_left_this_month
      assert_nil @user.generation_quota.refusal

      generate!(at: Time.current)
      assert_equal 0, @user.generations_left_this_month
      assert_equal :limit, @user.generation_quota.refusal
    end
  end

  test "the count starts again at midnight UTC on the first of the month" do
    3.times { generate!(at: Time.utc(2026, 10, 31, 23, 59, 59)) }

    travel_to Time.utc(2026, 10, 31, 23, 59, 59) do
      assert_equal 0, @user.generations_left_this_month
      assert_equal Date.new(2026, 11, 1), @user.generation_quota.resets_on
    end
    travel_to Time.utc(2026, 11, 1, 0, 0, 0) do
      assert_equal 3, @user.generations_left_this_month
    end
  end

  test "failed generations don't use up the quota" do
    travel_to Time.utc(2026, 10, 20) do
      3.times { generate!(at: Time.current) }
      @user.generations.last.update!(failed_at: Time.current)

      assert_equal 1, @user.generations_left_this_month
    end
  end

  test "deleting a path doesn't give its generation back" do
    path = learning_paths(:docker)
    travel_to Time.utc(2026, 10, 20) do
      generate!(at: Time.current, path: path)
      path.learning_goal.destroy!

      assert_equal 2, @user.reload.generations_left_this_month
      assert_nil Generation.sole.learning_path_id
    end
  end

  test "pro users get the fair-use allowance of thirty" do
    @user.update!(plan: :pro)
    generate!(at: Time.current)

    assert_equal 29, @user.generations_left_this_month
    assert_match "fair-use limit of 30 paths", @user.generation_quota.refusal_message(:limit)
  end

  test "the limit message for free users offers Pro and names the reset date" do
    travel_to Time.utc(2026, 10, 20) do
      message = @user.generation_quota.refusal_message(:limit)

      assert_equal "You’ve used your 3 free paths this month. Upgrade to Pro for more, or wait until 1 Nov.", message
    end
  end

  test "the demo account has no monthly quota" do
    demo = User.create!(email_address: DemoAccount.email, password: "pathaviator-demo")
    5.times { generate!(at: Time.current, user: demo) }

    assert demo.generation_quota.unlimited?
    assert_nil demo.generation_quota.refusal
  end

  test "everyone, the demo account included, is refused once the global daily cap is reached" do
    demo = User.create!(email_address: DemoAccount.email, password: "pathaviator-demo")

    with_env("AI_DAILY_GENERATION_LIMIT" => "2") do
      generate!(at: Time.current, user: users(:one))
      generate!(at: 1.day.ago, user: users(:one))
      assert_nil @user.generation_quota.refusal

      generate!(at: Time.current, user: demo)
      assert_equal :busy, @user.generation_quota.refusal
      assert_equal :busy, demo.generation_quota.refusal
    end
  end

  test "failed generations still count towards the daily cap because they cost money" do
    with_env("AI_DAILY_GENERATION_LIMIT" => "1") do
      generate!(at: Time.current).update!(failed_at: Time.current)

      assert Generation.daily_limit_reached?
    end
  end

  test "the daily cap defaults to 500" do
    with_env("AI_DAILY_GENERATION_LIMIT" => nil) do
      assert_equal 500, Generation.daily_limit
    end
  end
end
