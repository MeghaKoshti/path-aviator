require "test_helper"

class WeeklyDigestJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper
  # Sunday 1 November 2026, 18:00 in Kolkata (12:30 UTC).
  KOLKATA_SUNDAY_EVENING = Time.utc(2026, 11, 1, 12, 30)

  setup do
    @user = users(:one)
    @user.update!(time_zone: "Asia/Kolkata")
    path_steps(:rails_intro).update!(completed_at: KOLKATA_SUNDAY_EVENING - 2.days)
    users(:two).update!(weekly_digest: false)
  end

  def run_at(time)
    travel_to(time) { WeeklyDigestJob.perform_now }
  end

  test "emails users at 6pm on their own Sunday, once" do
    assert_enqueued_email_with WeeklyDigestMailer, :check_in, args: [ @user ] do
      run_at KOLKATA_SUNDAY_EVENING
    end
    assert_equal KOLKATA_SUNDAY_EVENING, @user.reload.weekly_digest_sent_at

    assert_no_enqueued_emails { run_at KOLKATA_SUNDAY_EVENING + 10.minutes }
  end

  test "it's not 6pm on Sunday everywhere at once" do
    assert_no_enqueued_emails { run_at KOLKATA_SUNDAY_EVENING - 1.hour }
    @user.update!(time_zone: "UTC")
    assert_no_enqueued_emails { run_at KOLKATA_SUNDAY_EVENING }
    assert_enqueued_emails(1) { run_at Time.utc(2026, 11, 1, 18, 5) }
  end

  test "next Sunday it is sent again" do
    run_at KOLKATA_SUNDAY_EVENING
    path_steps(:rails_models).update!(completed_at: KOLKATA_SUNDAY_EVENING + 3.days)

    assert_enqueued_emails(1) { run_at KOLKATA_SUNDAY_EVENING + 1.week }
  end

  test "skips people who opted out or haven't learned in 30 days" do
    @user.update!(weekly_digest: false)
    assert_no_enqueued_emails { run_at KOLKATA_SUNDAY_EVENING }

    @user.update!(weekly_digest: true)
    path_steps(:rails_intro).update!(completed_at: KOLKATA_SUNDAY_EVENING - 31.days)
    LearningGoal.update_all(created_at: KOLKATA_SUNDAY_EVENING - 40.days)
    assert_no_enqueued_emails { run_at KOLKATA_SUNDAY_EVENING }
  end

  test "skips addresses that were never confirmed" do
    @user.update_column(:email_verified_at, nil)

    assert_no_enqueued_emails { run_at KOLKATA_SUNDAY_EVENING }
  end

  test "never emails the shared demo account" do
    demo = DemoAccount.reset!
    demo.update!(time_zone: "Asia/Kolkata")
    @user.update!(weekly_digest: false)

    assert_no_enqueued_emails { run_at KOLKATA_SUNDAY_EVENING }
  end
end
