require "test_helper"
require "turbo/broadcastable/test_helper"

class GenerateLearningPathJobTest < ActiveJob::TestCase
  include Turbo::Broadcastable::TestHelper

  # Replays canned responses one per generator call. A response can be a
  # string, an exception to raise, or a proc that runs (simulating something
  # happening during the API call) and returns one of those.
  class ScriptedClient
    attr_reader :calls

    def initialize(*responses)
      @responses = responses
      @calls = 0
    end

    def generate(_goal)
      @calls += 1
      response = @responses.shift
      response = response.call if response.respond_to?(:call)
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

  def json_titled(title)
    JSON.parse(valid_json).merge("title" => title).to_json
  end

  # Deletes through a fresh record, like a web request would while the job runs.
  def delete_path_elsewhere
    LearningGoal.find(@path.learning_goal_id).destroy!
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

    assert_equal 2, streams.size, "path page and dashboard card"
    assert_equal %w[replace replace], streams.map { |stream| stream["action"] }
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

    assert_turbo_stream_broadcasts(stream, count: 2) { GenerateLearningPathJob.perform_now(@path) }
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

    assert_turbo_stream_broadcasts(stream, count: 2) { GenerateLearningPathJob.perform_now(@path) }

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

  test "exits quietly when the path is deleted during generation" do
    PathGenerator.client = ScriptedClient.new(-> { delete_path_elsewhere; valid_json })

    assert_no_turbo_stream_broadcasts(stream) do
      assert_nothing_raised { GenerateLearningPathJob.perform_now(@path) }
    end
    assert_not LearningPath.exists?(@path.id)
    assert_empty PathStep.where(learning_path_id: @path.id)
  end

  test "exits quietly when the path is deleted and the generator then fails" do
    PathGenerator.client = ScriptedClient.new(-> { delete_path_elsewhere; RuntimeError.new("boom") })

    assert_nothing_raised { GenerateLearningPathJob.perform_now(@path) }
    assert_not LearningPath.exists?(@path.id)
  end

  test "a slower job never overwrites steps a newer job already saved" do
    newer_job = -> { GenerateLearningPathJob.perform_now(LearningPath.find(@path.id)); json_titled("Stale path") }
    PathGenerator.client = ScriptedClient.new(newer_job, json_titled("Fresh path"))

    GenerateLearningPathJob.perform_now(@path)
    @path.reload

    assert @path.ready?
    assert_equal "Fresh path", @path.title
    assert_equal 8, @path.path_steps.count
  end

  test "a slower job that fails doesn't mark a newer job's finished path as failed" do
    newer_job = -> { GenerateLearningPathJob.perform_now(LearningPath.find(@path.id)); PathGenerator::Timeout.new("slow") }
    PathGenerator.client = ScriptedClient.new(newer_job, json_titled("Fresh path"))

    GenerateLearningPathJob.perform_now(@path)
    @path.reload

    assert @path.ready?
    assert_nil @path.error_message
    assert_equal "Fresh path", @path.title
  end

  test "saves the skills of a path planned from a job post" do
    @path.learning_goal.update!(job_post: "Analytics engineer: SQL, PostgreSQL and Python.")

    GenerateLearningPathJob.perform_now(@path)

    assert_equal [ "SQL", "PostgreSQL", "Python" ], @path.reload.skills
  end

  test "records a ready path with an estimated token count" do
    raw = valid_json
    PathGenerator.client = ScriptedClient.new(raw)
    GenerateLearningPathJob.perform_now(@path)

    event = Event.named(:path_ready).sole
    assert_equal @path.user, event.user
    assert_equal GenerateLearningPathJob::PROMPT_TOKENS + raw.length / 4, event.properties["estimated_tokens"]
  end

  test "records a failure and reports it as a warning" do
    PathGenerator.client = ScriptedClient.new(PathGenerator::Timeout.new("slow"))
    reports = []
    adapter = Object.new
    adapter.define_singleton_method(:call) { |error, **details| reports << [ error, details ] }
    ErrorReporter.adapter = adapter

    GenerateLearningPathJob.perform_now(@path)

    assert_equal "PathGenerator::Timeout: slow", Event.named(:path_failed).sole.properties["error"]
    assert_equal :warning, reports.sole.last[:severity]
  ensure
    ErrorReporter.adapter = nil
  end
end
