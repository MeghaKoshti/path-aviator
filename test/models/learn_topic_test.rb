require "test_helper"

class LearnTopicTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "ten curated topics with unique slugs, search-sized titles and descriptions" do
    topics = LearnTopic.all

    assert_equal 10, topics.size
    assert_equal topics.size, topics.map(&:slug).uniq.size
    assert_equal topics.size, topics.map(&:title).uniq.size
    topics.each do |topic|
      assert_match(/\A[a-z0-9]+(-[a-z0-9]+)*\z/, topic.slug)
      assert_operator topic.title.length, :<=, 60, topic.slug
      assert_includes 50..160, topic.description.length, topic.slug
    end
  end

  test "every topic is a valid path: 6 to 12 steps, known types, https links, weeks in order" do
    LearnTopic.all.each do |topic|
      assert_includes 6..12, topic.steps.size, topic.slug
      assert LearningGoal.current_levels.key?(topic.level), topic.slug
      assert_includes 1..40, topic.hours_per_week
      assert_equal topic.steps.map(&:week).sort, topic.steps.map(&:week), "#{topic.slug}: weeks out of order"
      assert_kind_of Date, topic.checked_on

      topic.steps.each do |step|
        assert_includes PathStep::RESOURCE_TYPES, step.resource_type, step.title
        assert step.url.start_with?("https://"), step.url
        assert PathStep.http_url?(step.url), step.url
        assert_operator step.minutes, :>, 0
        assert step.title.present? && step.description.present?
      end
    end
  end

  test "make this mine copies the plan into a ready path without an AI call" do
    topic = LearnTopic.find("sql-for-developers")

    path = nil
    assert_no_enqueued_jobs { path = topic.copy_for(users(:two)) }

    assert path.ready?
    assert_equal users(:two), path.user
    assert_equal topic.title, path.title
    assert_equal topic.steps.map(&:url), path.path_steps.map(&:resource_url)
    assert_equal [ "SQL for developers", "beginner", 4 ], path.learning_goal.values_at(:topic, :current_level, :hours_per_week)
  end

  test "every topic copies cleanly" do
    LearnTopic.all.each { |topic| assert topic.copy_for(users(:two)).persisted?, topic.slug }
  end

  test "an unknown slug is not found" do
    assert_raises(ActiveRecord::RecordNotFound) { LearnTopic.find("nope") }
  end
end
