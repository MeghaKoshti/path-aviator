# Send every error Rails sees to ErrorReporter (app/services/error_reporter.rb).
Rails.application.config.after_initialize do
  Rails.error.subscribe(ErrorReporter::Subscriber.new)
end
