require "test_helper"

class RecheckLinksJobTest < ActiveJob::TestCase
  test "queues a check for each active path of Pro users only" do
    with_pro_users(users(:one)) do
      assert_enqueued_jobs 1, only: CheckLinksJob do
        RecheckLinksJob.perform_now
      end
    end
    assert_enqueued_with(job: CheckLinksJob, args: [ learning_paths(:rails) ])
  end

  test "skips finished paths" do
    path = learning_paths(:rails)
    path.update_columns(completed_steps_count: path.path_steps_count)

    with_pro_users(users(:one)) do
      assert_no_enqueued_jobs(only: CheckLinksJob) { RecheckLinksJob.perform_now }
    end
  end

  test "free users get no weekly recheck" do
    assert_no_enqueued_jobs(only: CheckLinksJob) { RecheckLinksJob.perform_now }
  end

  private
    # Billing (User#pro?) lands in another branch. Until then, stand in for it.
    def with_pro_users(*pro_users)
      emails = pro_users.map(&:email_address)
      User.alias_method(:weekly_link_recheck_without_stub?, :weekly_link_recheck?)
      User.define_method(:weekly_link_recheck?) { emails.include?(email_address) }
      yield
    ensure
      User.alias_method(:weekly_link_recheck?, :weekly_link_recheck_without_stub?)
      User.remove_method(:weekly_link_recheck_without_stub?)
    end
end
