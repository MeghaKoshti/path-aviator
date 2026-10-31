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
end
