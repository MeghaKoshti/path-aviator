# The numbers behind the dashboard's "This week" panel, worked out from when
# a user's steps were ticked off.
#
# "Today" and "Monday" are in the user's own time zone unless one is passed in.
class LearningStats
  Day = Data.define(:date, :active, :today, :future)

  attr_reader :today

  def initialize(user, time_zone: user.zone, now: Time.current)
    @user = user
    @time_zone = time_zone
    @today = now.in_time_zone(time_zone).to_date
  end

  def week_start
    today.beginning_of_week(:monday)
  end

  # Minutes of the steps finished since Monday, 00:00.
  def minutes_this_week
    completions.sum { |date, minutes| date.between?(week_start, today) ? minutes : 0 }
  end

  # The most hours a week the user has set aside on any of their goals.
  def weekly_goal_minutes
    @weekly_goal_minutes ||= @user.learning_goals.maximum(:hours_per_week).to_i * 60
  end

  def goal_percent
    return 0 if weekly_goal_minutes.zero?

    (minutes_this_week * 100.0 / weekly_goal_minutes).round.clamp(0, 100)
  end

  def goal_reached?
    weekly_goal_minutes.positive? && minutes_this_week >= weekly_goal_minutes
  end

  # Days in a row with at least one finished step. The run may end yesterday,
  # so a streak isn't lost just because today's step isn't done yet.
  def streak
    day = active_dates.include?(today) ? today : today - 1
    count = 0
    while active_dates.include?(day)
      count += 1
      day -= 1
    end
    count
  end

  def active_today?
    active_dates.include?(today)
  end

  # Monday to Sunday of this week, for the little route on the dashboard.
  def week
    (week_start..week_start + 6).map do |date|
      Day.new(date:, active: active_dates.include?(date), today: date == today, future: date > today)
    end
  end

  def empty?
    completions.empty?
  end

  # Ready, unfinished paths with a target date, soonest first, each with
  # whether the learner is on track to finish in time.
  def deadlines
    @deadlines ||= @user.learning_paths.ready.joins(:learning_goal).where.not(learning_goals: { target_date: nil })
      .includes(:learning_goal, :path_steps).order("learning_goals.target_date")
      .reject(&:completed?)
      .map { |path| [ path, path.pace(today:) ] }
  end

  private
    # [date in the user's zone, minutes] for every finished step, in one query.
    # Dates are worked out in Ruby so time zones behave the same on any
    # database; a user has at most a few hundred finished steps.
    def completions
      @completions ||= PathStep.owned_by(@user).completed
        .pluck(:completed_at, :estimated_minutes)
        .map { |completed_at, minutes| [ completed_at.in_time_zone(@time_zone).to_date, minutes ] }
    end

    def active_dates
      @active_dates ||= completions.to_set(&:first)
    end
end
