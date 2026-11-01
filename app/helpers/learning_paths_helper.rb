module LearningPathsHelper
  RESOURCE_TYPES = {
    "video" => { label: "Video", action: "Watch the video" },
    "article" => { label: "Article", action: "Read the article" },
    "docs" => { label: "Docs", action: "Read the docs" },
    "course" => { label: "Course", action: "Open the course" },
    "practice" => { label: "Practice", action: "Start practising" }
  }.freeze

  # 45 → "45 min", 120 → "2 h", 135 → "2 h 15 min"
  def format_minutes(minutes)
    hours, mins = minutes.to_i.divmod(60)
    return "#{mins} min" if hours.zero?
    return "#{hours} h" if mins.zero?

    "#{hours} h #{mins} min"
  end

  def resource_type_label(type)
    RESOURCE_TYPES.dig(type, :label) || type.to_s.humanize
  end

  def resource_action_label(type)
    RESOURCE_TYPES.dig(type, :action) || "Open the resource"
  end

  def goal_level_label(goal)
    goal.current_level.to_s.humanize
  end

  def goal_pace_label(goal)
    "#{goal.hours_per_week} h a week"
  end

  def target_date_label(date)
    "Finish by #{l(date, format: "%-d %b %Y")}"
  end

  PACE_BADGES = { on_track: [ "On track", :success ], behind: [ "Behind", :warning ], done: [ "Finished", :success ] }.freeze

  def pace_word(pace)
    PACE_BADGES.dig(pace, 0)&.downcase
  end

  def pace_badge(pace)
    label, tone = PACE_BADGES[pace]
    ui_badge(label, tone) if label
  end

  # "6 h left, 3 weeks to go" for a path with a target date.
  def pace_detail(learning_path, today: Date.current)
    goal = learning_path.learning_goal
    return "Every step done." if learning_path.completed?
    return "#{format_minutes(learning_path.remaining_minutes)} left; the date has passed." if today > goal.target_date

    weeks = goal.weeks_left(today:)
    "#{format_minutes(learning_path.remaining_minutes)} left, #{pluralize(weeks, "week")} to go at #{goal.hours_per_week} h a week."
  end
end
