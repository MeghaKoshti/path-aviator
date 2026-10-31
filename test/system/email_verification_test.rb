require "application_system_test_case"

class EmailVerificationTest < ApplicationSystemTestCase
  # Jobs (the email included) go to the test adapter; deliver the emails
  # that were queued so far.
  include ActiveJob::TestHelper

  def delivered_email_to(address)
    perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob)
    ActionMailer::Base.deliveries.find { |mail| mail.to == [ address ] }
  end

  def plan_path(topic)
    visit new_learning_goal_path
    fill_in "Topic", with: topic
    click_on "Continue"
    click_on "Continue"
    click_on "Plan my path"
    assert_current_path %r{\A/learning_paths/\d+\z}
  end

  test "signing up, planning a first path, confirming the email, then planning a second" do
    visit new_registration_path
    fill_in "Email", with: "asha@example.com"
    fill_in "Password", with: "long-enough-pw"
    fill_in "Confirm password", with: "long-enough-pw"
    click_on "Create account"
    assert_text "Welcome aboard"

    plan_path "Docker"

    # The second path waits for the email to be confirmed.
    visit new_learning_goal_path
    assert_selector "h2", text: "Confirm your email to plan more paths"
    assert_no_field "Topic"

    email = delivered_email_to("asha@example.com")
    link = email.text_part.body.to_s[%r{http://\S+/verify_email/\S+}]
    visit URI(link).request_uri

    assert_text "Thanks, your email is confirmed."
    assert_no_selector "#verify_email"
    plan_path "Kubernetes"
    assert_equal 2, User.find_by!(email_address: "asha@example.com").learning_paths.count
  end
end
