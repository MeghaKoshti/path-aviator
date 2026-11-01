require "test_helper"

class WeeklyDigestMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:one) # Rails path: 1 of 4 steps done, goals of 6 h and 3 h a week
    @user.update!(time_zone: "Asia/Kolkata")
  end

  test "sums up the week in the user's zone with the next step and an unsubscribe link" do
    # Sunday 1 November, 18:00 in Kolkata.
    travel_to Time.utc(2026, 11, 1, 12, 30) do
      path_steps(:rails_intro).update!(completed_at: Time.utc(2026, 10, 31, 18, 0)) # Saturday 23:30 in Kolkata
      path_steps(:rails_models).update!(completed_at: Time.utc(2026, 10, 31, 19, 0)) # Sunday 00:30 there, still Saturday in UTC

      mail = WeeklyDigestMailer.check_in(@user)

      assert_equal [ "one@example.com" ], mail.to
      assert_equal "Your week: 2 h 30 min of 6 h, 2-day streak", mail.subject
      text = mail.text_part.body.to_s
      assert_includes text, "Hi Riya,"
      assert_includes text, "26 Oct to 1 Nov"
      assert_includes text, "Next step: Hotwire walkthrough (45 min, Ruby on Rails from zero to deploy)"
      assert_includes mail.html_part.body.to_s, "Hotwire walkthrough"

      url = mail.header["List-Unsubscribe"].value[1..-2]
      assert_includes text, url
      assert_equal "List-Unsubscribe=One-Click", mail.header["List-Unsubscribe-Post"].value
      assert_equal @user, User.find_by_token_for(:unsubscribe, url.split("/").last)
    end
  end

  test "a quiet week still reads well" do
    path_steps(:rails_intro).update!(completed_at: 3.weeks.ago)

    mail = WeeklyDigestMailer.check_in(@user)
    assert_equal "Your week: 0 min of 6 h", mail.subject
  end
end
