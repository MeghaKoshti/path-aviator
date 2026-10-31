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
end
