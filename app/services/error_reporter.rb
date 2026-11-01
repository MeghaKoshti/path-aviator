# Where errors go. Rails.error (and so every unhandled exception in a request
# or job, plus anything passed to Rails.error.report) reaches the adapter
# through ErrorReporter::Subscriber, registered in config/initializers.
#
# ERROR_REPORTER picks the adapter: "log" (default) writes to the Rails log.
# A Sentry or AppSignal adapter can be added later as one more class with a
# #call(error, handled:, severity:, context:, source:) method.
module ErrorReporter
  ADAPTERS = { "log" => "ErrorReporter::LogAdapter" }.freeze

  class << self
    attr_writer :adapter

    def adapter
      @adapter ||= ADAPTERS.fetch(ENV.fetch("ERROR_REPORTER", "log")) { ADAPTERS.fetch("log") }.constantize.new
    end
  end

  class Subscriber
    def report(error, handled:, severity:, context:, source: nil)
      ErrorReporter.adapter.call(error, handled:, severity:, context:, source:)
    rescue StandardError => e
      # A broken reporter must never take the app down with it.
      Rails.logger.error("[ErrorReporter] adapter failed: #{e.class}: #{e.message}")
    end
  end
end
