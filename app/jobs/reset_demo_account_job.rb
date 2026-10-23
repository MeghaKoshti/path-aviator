# Nightly clean-up of the shared demo account (config/recurring.yml): progress,
# notes, sharing and any paths visitors added go back to the seeded state.
class ResetDemoAccountJob < ApplicationJob
  queue_as :default

  def perform
    # Only an install that opted in to the public demo has one to reset.
    return unless ENV["SEED_DEMO"] == "1"

    DemoAccount.reset!
  end
end
