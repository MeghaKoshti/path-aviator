require "test_helper"

class EmailVerificationTest < ActiveSupport::TestCase
  setup do
    @user = users(:unverified)
  end

  test "a verification token finds its user and confirms the email" do
    token = @user.generate_token_for(:email_verification)

    assert_equal @user, User.find_by_token_for(:email_verification, token)
    assert_not @user.email_verified?
    @user.verify_email!
    assert @user.email_verified?
  end

  test "the token expires after three days" do
    token = @user.generate_token_for(:email_verification)

    travel 3.days - 1.minute do
      assert_equal @user, User.find_by_token_for(:email_verification, token)
    end
    travel 3.days + 1.minute do
      assert_nil User.find_by_token_for(:email_verification, token)
    end
  end

  test "a tampered token finds nobody" do
    token = @user.generate_token_for(:email_verification)

    assert_nil User.find_by_token_for(:email_verification, token.reverse)
    assert_nil User.find_by_token_for(:email_verification, "#{token}x")
  end

  test "changing the email resets verification and kills links sent to the old address" do
    user = users(:one)
    token = user.generate_token_for(:email_verification)

    user.update!(email_address: "new-address@example.com")

    assert_not user.email_verified?
    assert_nil User.find_by_token_for(:email_verification, token)
  end

  test "saving other fields keeps the email confirmed" do
    user = users(:one)
    user.update!(name: "Riya K")

    assert user.email_verified?
  end

  test "verifying twice keeps the first time" do
    user = users(:one)
    first = user.email_verified_at

    user.verify_email!

    assert_equal first, user.reload.email_verified_at
  end

  test "the demo account counts as confirmed" do
    demo = User.create!(email_address: DemoAccount.email, password: DemoAccount::PASSWORD)

    assert demo.email_verified?
    assert DemoAccount.reset!.email_verified_at
  end

  test "an unconfirmed account gets one path, then must confirm" do
    assert_nil @user.generation_quota.refusal

    @user.generations.create!

    assert_equal :unverified, @user.generation_quota.refusal
    assert_match "Confirm your email address", @user.generation_quota.refusal_message
    @user.verify_email!
    assert_nil @user.reload.generation_quota.refusal
  end

  test "a failed first generation doesn't count as the one free try" do
    @user.generations.create!(failed_at: Time.current)

    assert_nil @user.generation_quota.refusal
  end
end
