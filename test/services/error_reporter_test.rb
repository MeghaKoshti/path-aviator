require "test_helper"

class ErrorReporterTest < ActiveSupport::TestCase
  class RecordingAdapter
    attr_reader :reports

    def initialize = @reports = []
    def call(error, **details) = @reports << [ error, details ]
  end

  setup { @adapter = ErrorReporter.adapter = RecordingAdapter.new }
  teardown { ErrorReporter.adapter = nil }

  test "errors reported to Rails reach the adapter with their context" do
    error = RuntimeError.new("boom")
    Rails.error.report(error, handled: true, severity: :warning, context: { path_id: 7 })

    reported, details = @adapter.reports.last
    assert_same error, reported
    assert_equal true, details[:handled]
    assert_equal :warning, details[:severity]
    assert_equal 7, details[:context][:path_id]
  end

  test "unhandled errors in Rails.error.record are reported and re-raised" do
    assert_raises(ArgumentError) { Rails.error.record { raise ArgumentError, "bad" } }
    assert_equal false, @adapter.reports.last.last[:handled]
  end

  test "a broken adapter never raises into the app" do
    ErrorReporter.adapter = Class.new { def call(*, **) = raise("adapter down") }.new

    assert_nothing_raised { Rails.error.report(RuntimeError.new("boom"), handled: true) }
  end

  test "the log adapter writes one searchable line and the start of the backtrace" do
    log = StringIO.new
    error = RuntimeError.new("Gemini timed out")
    error.set_backtrace([ "app/jobs/x.rb:1", "app/jobs/y.rb:2" ])

    ErrorReporter::LogAdapter.new(logger: Logger.new(log)).call(error, handled: true, severity: :error, context: { path_id: 7 }, source: "application")

    assert_match "[ErrorReporter] error handled RuntimeError: Gemini timed out source=\"application\" path_id=7", log.string
    assert_match "[ErrorReporter]   app/jobs/x.rb:1", log.string
  end

  test "the log adapter is the default" do
    ErrorReporter.adapter = nil
    assert_instance_of ErrorReporter::LogAdapter, ErrorReporter.adapter
  end
end
