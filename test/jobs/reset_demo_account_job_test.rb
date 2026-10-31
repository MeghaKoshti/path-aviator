require "test_helper"

class ResetDemoAccountJobTest < ActiveJob::TestCase
  setup { @old_seed_demo = ENV["SEED_DEMO"] }
  teardown { ENV["SEED_DEMO"] = @old_seed_demo }

  test "resets the demo account when SEED_DEMO=1" do
    ENV["SEED_DEMO"] = "1"
    user = DemoAccount.reset!
    path = user.learning_paths.order(:id).first
    path.path_steps.incomplete.first.toggle_completion!
    path.unshare!

    ResetDemoAccountJob.perform_now

    assert_equal 3, path.reload.completed_steps_count
    assert path.shared?
  end

  test "does nothing without SEED_DEMO=1, so private installs get no demo account" do
    ENV["SEED_DEMO"] = nil

    assert_no_difference("User.count") { ResetDemoAccountJob.perform_now }
    assert_not User.exists?(email_address: DemoAccount.email)
  end

  test "runs nightly in production only" do
    schedule = YAML.load_file(Rails.root.join("config/recurring.yml"))

    assert_equal "ResetDemoAccountJob", schedule.dig("production", "reset_demo_account", "class")
    assert_match(/every day/, schedule.dig("production", "reset_demo_account", "schedule"))
    assert_equal [ "production" ], schedule.keys
  end
end
