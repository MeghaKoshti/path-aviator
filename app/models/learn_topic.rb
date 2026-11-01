# Read-only catalog of curated study plans from config/learn_topics.yml,
# published at /learn/:slug for people searching for a plan.
#
#   LearnTopic.find("sql-for-developers").steps.first.url
#   LearnTopic.find("sql-for-developers").copy_for(user) # => a ready LearningPath
class LearnTopic
  Step = Data.define(:week, :title, :description, :resource_type, :url, :minutes)

  attr_reader :slug, :title, :description, :topic, :level, :hours_per_week, :audience, :summary, :steps, :checked_on

  def self.all
    @all ||= YAML.load_file(Rails.root.join("config/learn_topics.yml"), permitted_classes: [ Date ]).map { |attrs| new(**attrs.symbolize_keys) }.freeze
  end

  def self.find(slug)
    all.find { |topic| topic.slug == slug } or raise ActiveRecord::RecordNotFound, "No study plan called #{slug}"
  end

  def initialize(slug:, title:, description:, topic:, level:, hours_per_week:, audience:, summary:, steps:, checked_on:)
    @slug, @title, @description, @topic, @level = slug, title, description, topic, level
    @hours_per_week, @audience, @summary, @checked_on = hours_per_week, audience, summary, checked_on
    @steps = steps.map do |step|
      Step.new(week: step["week"], title: step["title"], description: step["description"],
               resource_type: step["type"], url: step["url"], minutes: step["minutes"])
    end.freeze
  end

  def to_param = slug

  def weeks = steps.map(&:week).max
  def total_minutes = steps.sum(&:minutes)

  # Steps grouped by the week they start in: { 1 => [step, step], 2 => [...] }
  def steps_by_week = steps.group_by(&:week)

  # "Make this mine": the curated plan as the user's own path, ready to tick off.
  # No AI call is made, so it doesn't use a generation.
  def copy_for(user)
    LearningPath.transaction do
      goal = user.learning_goals.create!(topic:, current_level: level, hours_per_week:)
      goal.create_learning_path!(user:, title:, summary:, status: :ready, generated_at: Time.current).tap do |path|
        steps.each.with_index(1) do |step, position|
          path.path_steps.create!(position:, title: step.title, description: step.description,
            resource_type: step.resource_type, resource_url: step.url, estimated_minutes: step.minutes)
        end
      end
    end
  end
end
