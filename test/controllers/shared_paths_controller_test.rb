require "test_helper"

class SharedPathsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @path = learning_paths(:rails)
    @path.share!
  end

  test "anyone with the link sees the title, summary, steps and progress" do
    get shared_path_path(@path.share_token)

    assert_response :success
    assert_select "title", "#{@path.title} | Path Aviator"
    assert_select "meta[name=robots][content=noindex]"
    assert_equal "noindex", response.headers["X-Robots-Tag"]
    assert_select "h1", @path.title
    assert_select "p", @path.summary
    assert_select "p", "Riya is following this learning path"
    assert_select "progress[value='25']"
    assert_select "dd", "1 of 4"
    assert_select "ol > li", 4
    assert_select "h3", text: /Active Record basics/
    assert_select "a[href=?][target=_blank]", path_steps(:rails_hotwire).resource_url
    assert_select "a[href=?]", new_registration_path, text: "Plan my first path"
  end

  test "private details stay private" do
    get shared_path_path(@path.share_token)

    body = response.body
    assert_not_includes body, users(:one).email_address
    assert_not_includes body, "Sharma"
    assert_not_includes body, path_steps(:rails_intro).note
    assert_not_includes body, learning_goals(:rails).goal_description
    # Read-only: no ticking, no note editing, no path management.
    assert_select "form", false
    assert_select "[role=checkbox]", false
    assert_select "a[href*='/note']", false
    assert_select "turbo-cable-stream-source", false
  end

  test "an owner without a name is left out" do
    users(:one).update!(name: nil)

    get shared_path_path(@path.share_token)

    assert_select "p", "A learning path from Path Aviator"
  end

  test "signed-in visitors are offered their dashboard instead of sign-in" do
    sign_in_as users(:two)

    get shared_path_path(@path.share_token)

    assert_response :success
    assert_select "header a[href=?]", dashboard_path, text: "Your dashboard"
    assert_select "header a[href=?]", new_session_path, false
  end

  test "the link stops working once sharing is turned off" do
    token = @path.share_token
    @path.unshare!

    get shared_path_path(token)

    assert_response :not_found
  end

  test "a made-up token is not found" do
    get shared_path_path("x" * 24)
    assert_response :not_found
  end

  test "a shared path that is being re-planned is not found until it's ready" do
    @path.update!(status: :generating)

    get shared_path_path(@path.share_token)

    assert_response :not_found
  end
end
