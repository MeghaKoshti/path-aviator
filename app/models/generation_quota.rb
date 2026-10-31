# How many AI generations (new paths and regenerations) a user may still run,
# and why not when the answer is "none".
#
#   quota = GenerationQuota.new(user)
#   quota.remaining  # => 2
#   quota.refusal    # => nil, :busy or :limit
#
# Months are calendar months in the app's time zone (UTC).
class GenerationQuota
  attr_reader :user

  def initialize(user, now: Time.current)
    @user = user
    @now = now
  end

  def plan
    user.current_plan
  end

  def limit
    plan.monthly_generations
  end

  # The shared demo account must always work for visitors, so it has no
  # monthly quota (the global daily cap still applies).
  def unlimited?
    user.demo?
  end

  def used
    user.generations.counted.where(created_at: @now.all_month).count
  end

  def remaining
    [ limit - used, 0 ].max
  end

  def resets_on
    @now.next_month.beginning_of_month.to_date
  end

  # nil when a generation may start, otherwise the reason it may not.
  def refusal
    return :busy if Generation.daily_limit_reached?(now: @now)
    return if unlimited?

    :limit if remaining.zero?
  end

  def refusal_message(reason = refusal)
    reset_date = I18n.l(resets_on, format: "%-d %b")

    case reason
    when :busy
      "Path Aviator is very busy right now. Please try again in a little while."
    when :limit
      if plan.free?
        "You’ve used your #{limit} free paths this month. Upgrade to Pro for more, or wait until #{reset_date}."
      else
        "You’ve reached this month’s fair-use limit of #{limit} paths. It resets on #{reset_date}."
      end
    end
  end
end
