require "test_helper"

class EmailVerificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:unverified)
  end

  test "the emailed link confirms the address, even when signed out" do
    get verify_email_path(@user.generate_token_for(:email_verification))

    assert_redirected_to new_session_path
    assert_equal "Thanks, your email is confirmed.", flash[:notice]
    assert @user.reload.email_verified?
  end

  test "signed in, the link goes back to the dashboard" do
    sign_in_as @user

    get verify_email_path(@user.generate_token_for(:email_verification))

    assert_redirected_to dashboard_path
    assert @user.reload.email_verified?
  end

  test "an expired or tampered link is refused" do
    token = @user.generate_token_for(:email_verification)

    get verify_email_path("#{token}tampered")
    assert_match "invalid or has expired", flash[:alert]

    travel 4.days do
      get verify_email_path(token)
      assert_match "invalid or has expired", flash[:alert]
    end
    assert_not @user.reload.email_verified?
  end

  test "resending sends a fresh link, and is rate limited" do
    sign_in_as @user

    assert_enqueued_emails 3 do
      3.times { post email_verification_path }
    end
    assert_match "We sent a new link", flash[:notice]

    assert_no_enqueued_emails { post email_verification_path }
    assert_match "try again in 15 minutes", flash[:alert]
  end

  test "resending needs a session" do
    post email_verification_path

    assert_redirected_to new_session_path
  end

  test "nothing is sent to an address that is already confirmed" do
    sign_in_as users(:one)

    assert_no_enqueued_emails { post email_verification_path }
  end

  test "unconfirmed users see the prompt on the dashboard, confirmed ones don't" do
    sign_in_as @user
    get dashboard_path
    assert_select "#verify_email form[action=?] button", email_verification_path, text: "Resend the link"

    @user.verify_email!
    get dashboard_path
    assert_select "#verify_email", count: 0
  end

  test "after the first path, the new-path page asks for confirmation instead of the form" do
    sign_in_as @user
    @user.generations.create!

    get new_learning_goal_path
    assert_select "#verify_email h2", "Confirm your email to plan more paths"
    assert_select "form[action=?]", learning_goals_path, count: 0

    assert_no_difference "LearningPath.count" do
      post learning_goals_path, params: { learning_goal: { topic: "Docker", current_level: "beginner", hours_per_week: 3 } }
    end
    assert_response :forbidden
  end
end
