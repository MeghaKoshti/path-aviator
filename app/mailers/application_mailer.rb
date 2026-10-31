class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "Path Aviator <no-reply@pathaviator.dev>")
  layout "mailer"
end
