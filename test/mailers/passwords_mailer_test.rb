require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset emails come from the app's sender address" do
    email = PasswordsMailer.reset(users(:one))

    assert_equal [ "no-reply@pathaviator.dev" ], email.from
    assert_equal [ users(:one).email_address ], email.to
  end
end
