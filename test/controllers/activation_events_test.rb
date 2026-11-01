require "test_helper"

class ActivationEventsTest < ActionDispatch::IntegrationTest
  test "signing up is recorded" do
    post registration_path, params: { user: { email_address: "new@example.com", password: "long-enough-pw", password_confirmation: "long-enough-pw" } }

    assert Event.named(:signed_up).exists?(user: User.find_by(email_address: "new@example.com"))
  end

  test "the first ticked step is recorded once" do
    sign_in_as users(:one)

    patch toggle_path_step_path(path_steps(:rails_models))
    patch toggle_path_step_path(path_steps(:rails_hotwire))

    assert_equal 1, Event.named(:first_step_done).where(user: users(:one)).count
  end

  test "coming back in the second week after signing up is recorded once" do
    user = users(:one)
    user.update_columns(created_at: 9.days.ago)
    sign_in_as user

    2.times { get dashboard_path }
    assert_equal 1, Event.named(:returned_week_2).where(user: user).count
  end

  test "visits in the first week don't count as a week-2 return" do
    users(:one).update_columns(created_at: 2.days.ago)
    sign_in_as users(:one)
    get dashboard_path

    assert_not Event.named(:returned_week_2).exists?
  end
end
