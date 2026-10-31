# How many AI generations (new paths and regenerations) a user may still run,
# and why not when the answer is "none".
#
#   quota = GenerationQuota.new(user)
#   quota.remaining  # => 2
#   quota.refusal    # => nil, :busy, :unverified or :limit
#
# Months are calendar months in UTC, whatever zone the request runs in (each
# user's own, see ApplicationController), so everyone's quota resets together.
class GenerationQuota
  attr_reader :user

  def initialize(user, now: Time.current)
    @user = user
    @now = now.utc
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

  # An unconfirmed account gets one path, so trying the app stays quick but
  # throwaway sign-ups can't farm free generations.
  UNVERIFIED_GENERATIONS = 1

  # nil when a generation may start, otherwise the reason it may not.
  def refusal
    return :busy if Generation.daily_limit_reached?(now: @now)
    return if unlimited?
    return :unverified if awaiting_verification?

    :limit if remaining.zero?
  end

  def awaiting_verification?
    !user.email_verified? && user.generations.counted.count >= UNVERIFIED_GENERATIONS
  end

  def refusal_message(reason = refusal)
    reset_date = I18n.l(resets_on, format: "%-d %b")

    case reason
    when :busy
      "Path Aviator is very busy right now. Please try again in a little while."
    when :unverified
      "Confirm your email address to plan more paths. We sent a link to #{user.email_address}."
    when :limit
      if plan.free?
        "You’ve used your #{limit} free paths this month. Upgrade to Pro for more, or wait until #{reset_date}."
      else
        "You’ve reached this month’s fair-use limit of #{limit} paths. It resets on #{reset_date}."
      end
    end
  end
end
