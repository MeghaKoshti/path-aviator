require "test_helper"

class AccountMailerTest < ActionMailer::TestCase
  test "the verification email has HTML and text parts with a working link" do
    user = users(:unverified)
    email = AccountMailer.verify_email(user)

    assert_equal [ user.email_address ], email.to
    assert_equal [ "no-reply@pathaviator.dev" ], email.from
    assert_equal "Confirm your email for Path Aviator", email.subject
    assert_equal %w[text/plain text/html], email.parts.map(&:mime_type)

    html = email.html_part.body.to_s
    text = email.text_part.body.to_s
    token = text[%r{http://example.com/verify_email/(\S+)}, 1]

    assert_equal user, User.find_by_token_for(:email_verification, token)
    assert_includes html, "Confirm my email"
    assert_includes html, "Path Aviator"
    assert_includes text, "works for 3 days"
    assert_includes text, "Hi Kabir,"
  end

  test "transactional emails share the branded layout" do
    email = PasswordsMailer.reset(users(:one))

    assert_includes email.html_part.body.to_s, "Reset my password"
    assert_includes email.html_part.body.to_s, "You’re getting this email because of your account"
    assert_includes email.text_part.body.to_s, "You're getting this email because of your account"
  end
end
