require "test_helper"

class UnsubscribesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @token = @user.generate_token_for(:unsubscribe)
  end

  test "following the link unsubscribes without signing in" do
    get unsubscribe_path(@token)

    assert_response :success
    assert_select "h1", "You’re unsubscribed"
    assert_not @user.reload.weekly_digest?
  end

  test "changing your mind turns the email back on" do
    get unsubscribe_path(@token)
    delete unsubscribe_path(@token)

    assert_redirected_to unsubscribe_path(@token)
    assert @user.reload.weekly_digest?
  end

  test "mail clients can unsubscribe with a one-click POST" do
    post unsubscribe_path(@token), params: { "List-Unsubscribe" => "One-Click" }

    assert_response :ok
    assert_not @user.reload.weekly_digest?
  end

  test "a tampered token changes nothing" do
    get unsubscribe_path("#{@token}x")

    assert_response :not_found
    assert_select "h1", "This link doesn’t work"
    assert @user.reload.weekly_digest?
  end
end
