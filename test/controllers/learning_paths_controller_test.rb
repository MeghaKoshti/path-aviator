require "test_helper"

class LearningPathsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "requires sign-in" do
    delete session_path
    get learning_path_path(learning_paths(:rails))
    assert_redirected_to new_session_path
  end

  test "the page subscribes to the user's path stream" do
    get learning_path_path(learning_paths(:sql))

    stream = Turbo::StreamsChannel.signed_stream_name([ users(:one), :learning_paths ])
    assert_select "turbo-cable-stream-source[signed-stream-name=?]", stream
    assert_select "#path-announcer[aria-live=polite]"
    assert_select "##{dom_id(learning_paths(:sql))}"
  end

  test "a generating path shows the waiting state" do
    get learning_path_path(learning_paths(:sql))

    assert_response :success
    assert_select "h1", "Charting your route to SQL for analytics"
    assert_select "[data-path-status-status-value=generating][data-path-status-refresh-after-value='20000']"
    assert_select "dd", "Intermediate"
    assert_select "dd", "3 h a week"
  end

  test "a ready path shows its steps, progress and resource links" do
    path = learning_paths(:rails)

    get learning_path_path(path)

    assert_response :success
    assert_select "h1", path.title
    assert_select "##{dom_id(path, :steps)} > li", 4
    assert_select "##{dom_id(path, :progress)} progress[value='25']"
    assert_select "##{dom_id(path, :progress)} dd", "1 of 4"
    assert_select "##{dom_id(path, :progress)} dd", "3 h 45 min"
    assert_select "##{dom_id(path, :progress)} a[href=?]", "##{dom_id(path_steps(:rails_models))}", text: "Active Record basics"
    assert_select "a[href=?][target=_blank][rel='noopener noreferrer']", path_steps(:rails_hotwire).resource_url, text: /Watch the video/
    assert_select "##{dom_id(path_steps(:rails_models))}", text: /Up next/
  end

  test "a failed path explains what happened and offers to try again" do
    sign_in_as users(:two)
    path = learning_paths(:docker)

    get learning_path_path(path)

    assert_response :success
    assert_select "h1", "We couldn’t plan your route to Docker"
    assert_select "p", /We couldn't build this path/
    assert_select "form[action=?] button", regenerate_learning_path_path(path), text: "Try again"
  end

  test "someone else's path is not found" do
    get learning_path_path(learning_paths(:docker))
    assert_response :not_found
  end

  test "trying again on a failed path queues a new generation" do
    sign_in_as users(:two)
    path = learning_paths(:docker)

    assert_enqueued_with job: GenerateLearningPathJob, args: [ path ] do
      post regenerate_learning_path_path(path)
    end

    assert_redirected_to learning_path_path(path)
    assert path.reload.generating?
    assert_nil path.error_message
  end

  test "trying again while a path is still generating doesn't queue a duplicate" do
    assert_no_enqueued_jobs do
      post regenerate_learning_path_path(learning_paths(:sql))
    end
    assert_redirected_to learning_path_path(learning_paths(:sql))
  end
end
