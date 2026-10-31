module ErrorReporter
  # Writes one searchable line per error, plus the first lines of the backtrace.
  class LogAdapter
    def initialize(logger: Rails.logger)
      @logger = logger
    end

    def call(error, handled:, severity:, context:, source: nil)
      details = context.except(:controller, :job, :request).map { |key, value| "#{key}=#{value.inspect.truncate(80)}" }
      @logger.public_send(severity == :warning ? :warn : :error,
        "[ErrorReporter] #{severity} #{handled ? "handled" : "unhandled"} #{error.class}: #{error.message.truncate(300)} " \
        "source=#{source.inspect} #{details.join(" ")}".strip)
      Array(error.backtrace).first(5).each { |line| @logger.error("[ErrorReporter]   #{line}") }
    end
  end
end
