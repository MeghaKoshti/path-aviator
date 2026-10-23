require "test_helper"

class UserTest < ActiveSupport::TestCase
  def build_user(**attrs)
    User.new({ name: "Asha", email_address: "asha@example.com", password: "long-enough-pw" }.merge(attrs))
  end

  test "valid with name, email and an 8+ character password" do
    assert build_user.valid?
  end

  test "name is optional" do
    assert build_user(name: nil).valid?
  end

  test "blank name is stored as nil" do
    assert_nil build_user(name: "   ").name
  end

  test "normalizes email to stripped lowercase" do
    assert_equal "asha@example.com", build_user(email_address: "  ASHA@Example.COM ").email_address
  end

  test "requires an email address" do
    user = build_user(email_address: "")
    assert_not user.valid?
    assert user.errors.of_kind?(:email_address, :blank)
  end

  test "rejects a badly formatted email" do
    user = build_user(email_address: "not-an-email")
    assert_not user.valid?
    assert user.errors.of_kind?(:email_address, :invalid)
  end

  test "rejects a duplicate email regardless of case" do
    user = build_user(email_address: users(:one).email_address.upcase)
    assert_not user.valid?
    assert user.errors.of_kind?(:email_address, :taken)
  end

  test "requires a password on create" do
    user = build_user(password: nil)
    assert_not user.valid?
    assert user.errors.of_kind?(:password, :blank)
  end

  test "rejects a password shorter than 8 characters" do
    user = build_user(password: "short")
    assert_not user.valid?
    assert user.errors.of_kind?(:password, :too_short)
  end

  test "can be updated without touching the password" do
    user = users(:one)
    assert user.update(name: "New Name")
  end

  test "destroying a user removes their sessions" do
    user = users(:one)
    user.sessions.create!(ip_address: "127.0.0.1", user_agent: "test")
    assert_difference("Session.count", -1) { user.destroy }
  end
end
