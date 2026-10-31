require "test_helper"
require "turbo/broadcastable/test_helper"

class CheckLinksJobTest < ActiveJob::TestCase
  include Turbo::Broadcastable::TestHelper

  # Generator stand-in for single-step replacements.
  class ReplacingClient
    attr_reader :asked_for

    def initialize(*answers)
      @answers = answers
      @asked_for = []
    end

    def replace_step(step)
      @asked_for << step.title
      answer = @answers.shift
      answer.is_a?(Exception) ? raise(answer) : answer
    end
  end

  setup do
    @path = learning_paths(:rails)
    @step = path_steps(:rails_models)
  end

  teardown do
    PathGenerator.client = nil
  end

  def replacement(url = "https://edgeguides.rubyonrails.org/active_record_basics.html")
    { description: "Read the edge guide instead.", resource_type: "docs", resource_url: url }.to_json
  end

  test "marks every working link as checked" do
    checker = LinkChecker::Fake.new

    freeze_time do
      CheckLinksJob.perform_now(@path, checker: checker)

      assert_equal @path.path_steps.map(&:resource_url), checker.checked
      @path.path_steps.reload.each do |step|
        assert step.link_ok?, step.title
        assert_equal Time.current, step.link_checked_at
      end
    end
  end

  test "links that block checkers are unverified and left alone" do
    PathGenerator.client = client = ReplacingClient.new
    CheckLinksJob.perform_now(@path, checker: LinkChecker::Fake.new(unverified: [ @step.resource_url ]))

    assert @step.reload.link_unverified?
    assert_empty client.asked_for
  end

  test "a broken link is swapped for a working substitute from the generator" do
    PathGenerator.client = client = ReplacingClient.new(replacement)
    CheckLinksJob.perform_now(@path, checker: LinkChecker::Fake.new(broken: [ @step.resource_url ]))
    @step.reload

    assert_equal [ "Active Record basics" ], client.asked_for
    assert @step.link_ok?
    assert_equal "https://edgeguides.rubyonrails.org/active_record_basics.html", @step.resource_url
    assert_equal "Read the edge guide instead.", @step.description
    assert_equal "Active Record basics", @step.title, "the step itself stays the same"
    assert_equal 60, @step.estimated_minutes
  end

  test "a substitute that is broken too leaves the step flagged with its original link" do
    original = @step.resource_url
    PathGenerator.client = ReplacingClient.new(replacement("https://also-gone.example/"))
    CheckLinksJob.perform_now(@path, checker: LinkChecker::Fake.new(broken: [ original, "https://also-gone.example/" ]))
    @step.reload

    assert @step.link_broken?
    assert_equal original, @step.resource_url
  end

  test "a generator failure leaves the step flagged" do
    PathGenerator.client = ReplacingClient.new(PathGenerator::Timeout.new("slow"))
    CheckLinksJob.perform_now(@path, checker: LinkChecker::Fake.new(broken: [ @step.resource_url ]))

    assert @step.reload.link_broken?
  end

  test "an invalid or repeated substitute is ignored" do
    PathGenerator.client = ReplacingClient.new(replacement(@step.resource_url))
    CheckLinksJob.perform_now(@path, checker: LinkChecker::Fake.new(broken: [ @step.resource_url ]))

    assert @step.reload.link_broken?
  end

  test "does not overwrite a step whose link changed while it was being checked" do
    checker = LinkChecker::Fake.new
    checker.define_singleton_method(:check) do |url|
      PathStep.where(id: ActiveRecord::FixtureSet.identify(:rails_models)).update_all(resource_url: "https://new.example/") if url.include?("active_record")
      super(url)
    end

    CheckLinksJob.perform_now(@path, checker: checker)

    assert @step.reload.link_unchecked?
    assert_equal "https://new.example/", @step.resource_url
  end

  test "updates each step's link on the page over the path's stream" do
    streams = capture_turbo_stream_broadcasts([ @path.user, :learning_paths ]) do
      CheckLinksJob.perform_now(@path, checker: LinkChecker::Fake.new)
    end

    assert_equal 4, streams.size
    assert_equal "resource_path_step_#{@step.id}", streams.second["target"]
    assert_includes streams.second.to_html, "Link checked"
  end

  test "skips paths that aren't ready" do
    checker = LinkChecker::Fake.new
    CheckLinksJob.perform_now(learning_paths(:sql), checker: checker)

    assert_empty checker.checked
  end

  test "the generation job queues a link check once the path is saved" do
    path = learning_paths(:sql)
    PathGenerator.client = nil

    assert_enqueued_with(job: CheckLinksJob, args: [ path ]) do
      GenerateLearningPathJob.perform_now(path)
    end
  end

  test "a failed generation queues no link check" do
    PathGenerator.client = Class.new { def generate(_) = "not json" }.new

    assert_no_enqueued_jobs(only: CheckLinksJob) { GenerateLearningPathJob.perform_now(learning_paths(:sql)) }
  end
end
