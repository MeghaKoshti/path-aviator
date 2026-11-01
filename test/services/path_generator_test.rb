require "test_helper"

class PathGeneratorTest < ActiveSupport::TestCase
  # Returns canned responses in order, so a test can script each attempt.
  class ScriptedClient
    attr_reader :calls

    def initialize(*responses)
      @responses = responses
      @calls = 0
    end

    def generate(_goal)
      @calls += 1
      response = @responses.shift
      response.is_a?(Exception) ? raise(response) : response
    end
  end

  setup do
    @goal = learning_goals(:rails)
  end

  teardown do
    PathGenerator.client = nil
  end

  def valid_json(steps: 6)
    {
      title: "Rails path",
      summary: "Learn Rails.",
      steps: Array.new(steps) do |i|
        { title: "Step #{i + 1}", description: "Do it.", resource_type: "Docs", resource_url: "https://example.com/#{i}", estimated_minutes: 30 }
      end
    }.to_json
  end

  test "uses the fake client in tests" do
    assert_instance_of PathGenerator::Fake, PathGenerator.client
  end

  test "the client can be overridden" do
    client = ScriptedClient.new(valid_json)
    PathGenerator.client = client
    assert_same client, PathGenerator.client
  end

  test "returns a normalised result with the raw text" do
    raw = valid_json
    PathGenerator.client = ScriptedClient.new(raw)

    result = PathGenerator.call(@goal)

    assert_equal "Rails path", result.title
    assert_equal "Learn Rails.", result.summary
    assert_equal 6, result.steps.size
    assert_equal "docs", result.steps.first[:resource_type]
    assert_equal raw, result.raw
  end

  test "accepts JSON wrapped in a markdown fence" do
    PathGenerator.client = ScriptedClient.new("```json\n#{valid_json}\n```")
    assert_equal "Rails path", PathGenerator.call(@goal).title
  end

  test "raises InvalidOutput with the raw text for broken JSON" do
    PathGenerator.client = ScriptedClient.new("{ not json")

    error = assert_raises(PathGenerator::InvalidOutput) { PathGenerator.call(@goal) }
    assert_equal "{ not json", error.raw
  end

  test "raises InvalidOutput when validation fails" do
    PathGenerator.client = ScriptedClient.new(valid_json(steps: 3))

    error = assert_raises(PathGenerator::InvalidOutput) { PathGenerator.call(@goal) }
    assert_match "6-12 items", error.message
  end

  test "lets timeouts from the client through" do
    PathGenerator.client = ScriptedClient.new(PathGenerator::Timeout.new("slow"))
    assert_raises(PathGenerator::Timeout) { PathGenerator.call(@goal) }
  end

  test "fake output passes validation and adapts to the topic" do
    result = PathGenerator.call(@goal)

    assert_equal 8, result.steps.size
    assert_includes result.title, "Ruby on Rails"
    result.steps.each.with_index(1) do |step, position|
      assert PathStep.new(step.merge(position:, learning_path: learning_paths(:sql))).valid?, step[:title]
    end
  end

  test "replace_step returns a validated substitute for one step" do
    step = path_steps(:rails_models)
    PathGenerator.client = Struct.new(:raw) { def replace_step(_) = raw }.new(
      { description: " Read the edge guide. ", resource_type: "Docs", resource_url: " https://edgeguides.rubyonrails.org/ " }.to_json
    )

    replacement = PathGenerator.replace_step(step)

    assert_equal "Read the edge guide.", replacement.description
    assert_equal "docs", replacement.resource_type
    assert_equal "https://edgeguides.rubyonrails.org/", replacement.resource_url
  end

  test "replace_step rejects invalid substitutes and the same broken link" do
    step = path_steps(:rails_models)
    [
      { description: "x", resource_type: "podcast", resource_url: "https://a.example" },
      { description: "x", resource_type: "docs", resource_url: "ftp://a.example" },
      { resource_type: "docs", resource_url: "https://a.example" },
      { description: "x", resource_type: "docs", resource_url: step.resource_url }
    ].each do |answer|
      PathGenerator.client = Struct.new(:raw) { def replace_step(_) = raw }.new(answer.to_json)
      assert_raises(PathGenerator::InvalidOutput, answer.inspect) { PathGenerator.replace_step(step) }
    end
  end

  test "the fake generator offers a valid substitute" do
    step = path_steps(:rails_models)
    replacement = PathGenerator.replace_step(step)

    assert_match %r{\Ahttps://}, replacement.resource_url
    assert_not_equal step.resource_url, replacement.resource_url
  end

  test "the fake generator picks skills out of a job post and fits a target date" do
    travel_to Date.new(2026, 10, 31) do
      goal = LearningGoal.new(topic: "Backend developer", current_level: :intermediate, hours_per_week: 2, target_date: Date.new(2026, 11, 21),
                              job_post: "We ship Ruby on Rails with PostgreSQL, Redis and Sidekiq on AWS. Go-getters welcome!")
      result = PathGenerator.call(goal)

      assert_equal [ "Ruby on Rails", "Sidekiq", "PostgreSQL", "Redis", "AWS" ], result.skills
      assert_operator result.steps.sum { |step| step[:estimated_minutes] }, :<=, 3 * 2 * 60 * PathGenerator::Validator::BUDGET_SLACK
    end
  end

  test "a topic path has no skills" do
    assert_equal [], PathGenerator.call(@goal).skills
  end

  test "a job-post answer without skills is invalid" do
    goal = LearningGoal.new(topic: "Backend developer", current_level: :beginner, hours_per_week: 4, job_post: "Rails role")
    PathGenerator.client = ScriptedClient.new(valid_json)

    error = assert_raises(PathGenerator::InvalidOutput) { PathGenerator.call(goal) }
    assert_match "skills", error.message
  end
end
