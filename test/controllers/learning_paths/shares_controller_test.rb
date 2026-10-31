require "test_helper"

class LearningPaths::SharesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @path = learning_paths(:rails)
  end

  test "a private path offers to create a share link" do
    get learning_path_path(@path)

    assert_select "section#share" do
      assert_select "h2", "Share this path"
      assert_select "p", text: /Your notes and email stay private/
      assert_select "form[action=?] button", learning_path_share_path(@path), text: "Create share link"
      assert_select "input[readonly]", false
    end
  end

  test "creating a link shares the path and shows the link with copy, new link and stop sharing" do
    post learning_path_share_path(@path)

    token = @path.reload.share_token
    assert_equal 24, token.length
    assert_redirected_to learning_path_path(@path, anchor: "share")
    follow_redirect!
    assert_select "[role=status]", /Share link created/
    assert_select "section#share" do
      assert_select "label.sr-only[for=?]", dom_id(@path, :share_url), text: "Share link"
      assert_select "input[readonly][value=?]", shared_path_url(token)
      assert_select "[data-controller=clipboard][data-clipboard-path-value=?]", shared_path_path(token)
      assert_select "button[data-action='clipboard#copy']", "Copy link"
      assert_select "[role=status][data-clipboard-target=status]"
      assert_select "form[action=?] button[data-turbo-confirm*='stop working']", learning_path_share_path(@path), text: "New link"
      assert_select "form[action=?] input[name=_method][value=delete]", learning_path_share_path(@path)
    end
  end

  test "a new link replaces the old one" do
    @path.share!
    old_token = @path.share_token

    post learning_path_share_path(@path)

    assert_not_equal old_token, @path.reload.share_token
    follow_redirect!
    assert_select "[role=status]", /New link created. The old link no longer works./
    get shared_path_path(old_token)
    assert_response :not_found
  end

  test "stopping sharing clears the token so the link 404s" do
    @path.share!
    token = @path.share_token

    delete learning_path_share_path(@path)

    assert_nil @path.reload.share_token
    assert_redirected_to learning_path_path(@path, anchor: "share")
    get shared_path_path(token)
    assert_response :not_found
  end

  test "someone else's path can't be shared or unshared" do
    path = learning_paths(:docker)

    post learning_path_share_path(path)
    assert_response :not_found
    assert_nil path.reload.share_token

    path.share!
    delete learning_path_share_path(path)
    assert_response :not_found
    assert path.reload.shared?
  end

  test "requires sign-in" do
    delete session_path

    post learning_path_share_path(@path)

    assert_redirected_to new_session_path
    assert_nil @path.reload.share_token
  end
end
