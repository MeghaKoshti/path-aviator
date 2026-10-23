require "test_helper"
require "rake"

class PathAviatorTasksTest < ActiveSupport::TestCase
  class CannedClient
    def initialize(raw) = @raw = raw
    def generate(_goal) = @raw
  end

  class WritingClient
    def generate(_goal)
      User.create!(email_address: "sneaky@example.com", password: "long-enough-pw")
    end
  end

  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("path_aviator:smoke_generate")
    @task = Rake::Task["path_aviator:smoke_generate"]
    @task.reenable
    @old_key = ENV["GEMINI_API_KEY"]
    # Tests always get the Fake client, even with a key set.
    ENV["GEMINI_API_KEY"] = "test-key"
  end

  teardown do
    ENV["GEMINI_API_KEY"] = @old_key
    PathGenerator.client = nil
  end

  def smoke(*args)
    capture_io { @task.invoke(*args) }
  end

  test "prints the validated path, step list and timing without saving anything" do
    out, = assert_no_difference [ "LearningGoal.count", "LearningPath.count", "PathStep.count" ] do
      smoke("Kubernetes", "intermediate", "4")
    end

    assert_includes out, "Client: PathGenerator::Fake"
    assert_includes out, "Goal:   Kubernetes (intermediate, 4 h/week)"
    assert_includes out, "Validation: passed"
    assert_includes out, "Kubernetes: Intermediate Learning Path"
    assert_match(/^8\. Build and share a small project \[practice, 240 min\]$/, out)
    assert_includes out, "8 steps, 870 minutes in total"
    assert_match(/^Time: \d+\.\ds$/, out)
  end

  test "uses sensible defaults when no arguments are given" do
    out, = smoke

    assert_includes out, "Goal:   Ruby on Rails (beginner, 5 h/week)"
  end

  test "refuses to run without an API key" do
    ENV["GEMINI_API_KEY"] = nil

    _, err = capture_io { assert_raises(SystemExit) { @task.invoke } }

    assert_includes err, "GEMINI_API_KEY is not set"
  end

  test "reports invalid output with the raw response and exits non-zero" do
    PathGenerator.client = CannedClient.new("not json")

    out, = capture_io do
      error = assert_raises(SystemExit) { @task.invoke }
      assert_equal 1, error.status
    end

    assert_includes out, "Validation: FAILED (Response is not valid JSON"
    assert_includes out, "Raw response:\nnot json"
  end

  test "rejects bad input before calling the generator" do
    out, = capture_io { assert_raises(SystemExit) { @task.invoke("Go", "expert", "0") } }

    assert_includes out, "Invalid input: Topic is too short"
    assert_includes out, "Invalid input: Current level is not included in the list"
    assert_includes out, "Invalid input: Hours per week must be between 1 and 40"
    assert_not_includes out, "Client:"
  end

  test "blocks database writes during the generator call" do
    PathGenerator.client = WritingClient.new

    assert_no_difference "User.count" do
      capture_io { assert_raises(ActiveRecord::ReadOnlyError) { @task.invoke } }
    end
  end
end
