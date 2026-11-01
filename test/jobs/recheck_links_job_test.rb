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
    def with_pro_users(*pro_users)
      pro_users.each { |user| user.update!(plan: :pro) }
      yield
    end
end
