module LearnTopicsHelper
  # "Week 3", or "Weeks 8–9" when the next group starts later.
  def learn_week_label(week, next_week)
    last = next_week ? next_week - 1 : week
    last > week ? "Weeks #{week}–#{last}" : "Week #{week}"
  end

  def learn_topic_facts(topic)
    "#{pluralize(topic.weeks, "week")}, #{topic.hours_per_week} h a week"
  end
end
