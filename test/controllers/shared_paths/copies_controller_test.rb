require "test_helper"

class SharedPaths::CopiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @path = learning_paths(:rails)
    @path.share!
  end

  test "a signed-in visitor gets their own copy and lands on it" do
    sign_in_as users(:two)

    assert_difference -> { users(:two).learning_paths.count } => 1, -> { users(:one).learning_paths.count } => 0 do
      post copy_shared_path_path(@path.share_token)
    end

    copy = users(:two).learning_paths.order(:id).last
    assert_redirected_to learning_path_path(copy)
    assert_equal @path.title, copy.title
    assert_no_enqueued_jobs only: GenerateLearningPathJob
  end

  test "guests are asked to sign in and come back to the shared page" do
    assert_no_difference "LearningPath.count" do
      post copy_shared_path_path(@path.share_token)
    end

    assert_redirected_to new_session_path
    sign_in_as users(:two)
    assert_redirected_to shared_path_url(@path.share_token)
  end

  test "an unshared or unknown link can't be copied" do
    sign_in_as users(:two)
    token = @path.share_token
    @path.unshare!

    post copy_shared_path_path(token)
    assert_response :not_found
  end

  test "the share page offers the copy: a form when signed in, sign-up otherwise" do
    get shared_path_path(@path.share_token)
    assert_select "a[href=?]", new_registration_path(copy: @path.share_token), text: "Copy this path"

    sign_in_as users(:two)
    get shared_path_path(@path.share_token)
    assert_select "form[action=?] button", copy_shared_path_path(@path.share_token), text: "Copy this path"
  end

  test "signing up from the copy link creates the account and the copy" do
    get new_registration_path(copy: @path.share_token)
    assert_select "input[type=hidden][name=copy][value=?]", @path.share_token

    post registration_path, params: { copy: @path.share_token,
      user: { email_address: "new@example.com", password: "long-enough-pw", password_confirmation: "long-enough-pw" } }

    user = User.find_by!(email_address: "new@example.com")
    assert_redirected_to learning_path_path(user.learning_paths.sole)
    assert_equal @path.title, user.learning_paths.sole.title
  end
end
