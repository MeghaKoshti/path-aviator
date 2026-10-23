require "test_helper"
require "turbo/broadcastable/test_helper"

class GenerateLearningPathJobTest < ActiveJob::TestCase
  include Turbo::Broadcastable::TestHelper

  # Replays canned responses (strings or exceptions) one per generator call.
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
    @path = learning_paths(:sql)
  end

  teardown do
    PathGenerator.client = nil
  end

  def valid_json
    PathGenerator::Fake.new.generate(@path.learning_goal)
  end

  def stream
    [ @path.user, :learning_paths ]
  end

  test "builds the steps and marks the path ready" do
    raw = valid_json
    PathGenerator.client = ScriptedClient.new(raw)

    GenerateLearningPathJob.perform_now(@path)
    @path.reload

    assert @path.ready?
    assert_equal "SQL for analytics: Intermediate Learning Path", @path.title
    assert @path.summary.present?
    assert_equal raw, @path.raw_response
    assert_not_nil @path.generated_at
    assert_equal 8, @path.path_steps_count
    assert_equal (1..8).to_a, @path.path_steps.map(&:position)
    assert_equal 0, @path.completed_steps_count
  end

  test "broadcasts the refreshed path card when done" do
    PathGenerator.client = ScriptedClient.new(valid_json)

    streams = capture_turbo_stream_broadcasts(stream) { GenerateLearningPathJob.perform_now(@path) }

    assert_equal 1, streams.size
    assert_equal "replace", streams.first["action"]
    assert_includes streams.first.to_html, "SQL for analytics"
  end

  test "retries once after invalid JSON and succeeds" do
    client = ScriptedClient.new("not json", valid_json)
    PathGenerator.client = client

    GenerateLearningPathJob.perform_now(@path)

    assert_equal 2, client.calls
    assert @path.reload.ready?
  end

  test "fails after two invalid answers and keeps the raw text for debugging" do
    client = ScriptedClient.new("not json", "still not json")
    PathGenerator.client = client

    assert_turbo_stream_broadcasts(stream, count: 1) { GenerateLearningPathJob.perform_now(@path) }
    @path.reload

    assert_equal 2, client.calls
    assert @path.failed?
    assert_equal "We couldn't build this path. Please try again.", @path.error_message
    assert_equal "still not json", @path.raw_response
    assert_equal 0, @path.path_steps_count
  end

  test "fails without retrying on timeout" do
    client = ScriptedClient.new(PathGenerator::Timeout.new("slow"), valid_json)
    PathGenerator.client = client

    assert_turbo_stream_broadcasts(stream, count: 1) { GenerateLearningPathJob.perform_now(@path) }

    assert_equal 1, client.calls
    assert @path.reload.failed?
    assert_equal GenerateLearningPathJob::FAILURE_MESSAGE, @path.error_message
  end

  test "fails on request errors" do
    PathGenerator.client = ScriptedClient.new(PathGenerator::RequestFailed.new("HTTP 503"))

    GenerateLearningPathJob.perform_now(@path)

    assert @path.reload.failed?
  end

  test "marks the path failed and re-raises unexpected errors" do
    PathGenerator.client = ScriptedClient.new(RuntimeError.new("boom"))

    assert_raises(RuntimeError) { GenerateLearningPathJob.perform_now(@path) }
    assert @path.reload.failed?
  end

  test "does nothing for a path that is no longer generating" do
    path = learning_paths(:rails)
    client = ScriptedClient.new(valid_json)
    PathGenerator.client = client

    assert_no_changes -> { path.reload.updated_at } do
      GenerateLearningPathJob.perform_now(path)
    end
    assert_equal 0, client.calls
  end

  test "is discarded when the path was deleted before it ran" do
    GenerateLearningPathJob.perform_later(@path)
    @path.destroy

    assert_nothing_raised { perform_enqueued_jobs }
  end
end
