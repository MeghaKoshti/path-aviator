require "test_helper"

# The shared demo login: its settings are locked on the server, the learning
# features work as for anyone else.
class DemoAccountControllersTest < ActionDispatch::IntegrationTest
  LOCKED = SettingsController::DEMO_LOCKED_NOTICE

  setup do
    @demo = DemoAccount.reset!
    sign_in_as @demo, password: DemoAccount::PASSWORD
  end

  test "the settings page shows the forms disabled with a note" do
    get settings_path

    assert_response :success
    assert_select "#demo-locked-note", LOCKED
    assert_select "fieldset[disabled][aria-describedby=demo-locked-note]", 4
    assert_select "form[action=?] fieldset[disabled] input[type=submit][value='Save profile']", settings_profile_path
    assert_select "form[action=?] fieldset[disabled]", settings_password_path
    assert_select "form[action=?] fieldset[disabled]", settings_account_path
  end

  test "the name and email can't be changed" do
    patch settings_profile_path, params: { user: { name: "Someone", email_address: "mine@example.com", password_challenge: DemoAccount::PASSWORD } }

    assert_redirected_to settings_path
    assert_equal LOCKED, flash[:notice]
    @demo.reload
    assert_equal [ "Demo Learner", "demo@pathaviator.dev" ], [ @demo.name, @demo.email_address ]
  end

  test "the password can't be changed" do
    patch settings_password_path, params: { user: { password_challenge: DemoAccount::PASSWORD, password: "taken-over-pw", password_confirmation: "taken-over-pw" } }

    assert_redirected_to settings_path
    assert_equal LOCKED, flash[:notice]
    assert @demo.reload.authenticate(DemoAccount::PASSWORD)
  end

  test "the account can't be deleted" do
    assert_no_difference [ "User.count", "LearningPath.count" ] do
      delete settings_account_path, params: { confirmation: "DELETE" }
    end

    assert_redirected_to settings_path
    follow_redirect!
    assert_select "[role=status]", LOCKED
  end

  test "a password reset for the demo email sends nothing but looks the same as any other" do
    delete session_path
    post passwords_path, params: { email_address: users(:one).email_address }
    known = [ response.status, response.location, flash[:notice] ]

    assert_no_enqueued_emails do
      post passwords_path, params: { email_address: " Demo@PathAviator.dev " }
    end

    assert_equal known, [ response.status, response.location, flash[:notice] ]
  end

  test "learning features still work: onboarding, notes, ticking and sharing" do
    assert_difference "@demo.learning_paths.count", 1 do
      post learning_goals_path, params: { learning_goal: { topic: "SQL", current_level: "beginner", hours_per_week: 2 } }
    end

    path = @demo.learning_paths.find_by!(title: "Git and GitHub essentials")
    step = path.path_steps.first

    patch path_step_note_path(step), params: { path_step: { note: "Visitor note" } }
    assert_equal "Visitor note", step.reload.note

    patch toggle_path_step_path(step)
    assert_not step.reload.completed?

    post learning_path_share_path(path)
    assert path.reload.shared?
  end
end
