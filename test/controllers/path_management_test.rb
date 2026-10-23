require "test_helper"

class PathManagementTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @path = learning_paths(:rails)
  end

  test "a ready path offers regenerate and delete, both behind a confirmation" do
    get learning_path_path(@path)

    assert_select "form[action=?] button[data-turbo-confirm*='progress and notes will be cleared']", regenerate_learning_path_path(@path), text: "Regenerate"
    assert_select "form[action=?] input[name=_method][value=delete]", learning_path_path(@path)
    assert_select "form[action=?] button[data-turbo-confirm*='gone for good']", learning_path_path(@path), text: "Delete path"
  end

  test "regenerating a ready path clears progress and queues generation" do
    assert_enqueued_with job: GenerateLearningPathJob, args: [ @path ] do
      post regenerate_learning_path_path(@path)
    end

    assert_redirected_to learning_path_path(@path)
    @path.reload
    assert @path.generating?
    assert_equal 0, @path.path_steps_count
    assert_equal 0, @path.completed_steps_count
  end

  test "deleting from the path page removes the path, its steps and goal" do
    assert_difference -> { LearningPath.count } => -1, -> { LearningGoal.count } => -1, -> { PathStep.count } => -4 do
      delete learning_path_path(@path)
    end

    assert_redirected_to dashboard_path
    follow_redirect!
    assert_select "[role=status]", /Deleted “Ruby on Rails from zero to deploy”/
  end

  test "deleting from the dashboard removes the card over a Turbo Stream" do
    delete learning_path_path(@path), params: { from: "dashboard" }, as: :turbo_stream

    assert_response :success
    assert_select "turbo-stream[action=remove][target=?]", dom_id(@path, :card)
    assert_select "turbo-stream[action=replace][target=dashboard_header] template h1[autofocus][tabindex='-1']"
    assert_select "turbo-stream[action=replace][target=dashboard_header] template", text: /1 path, 0 complete/
    assert_select "turbo-stream[action=replace][target=flash] template [role=status]", text: /Deleted/
    assert_select "turbo-stream[target=learning_path_cards]", false
    assert_not LearningPath.exists?(@path.id)
  end

  test "deleting the last path shows the empty state" do
    learning_paths(:sql).learning_goal.destroy!

    delete learning_path_path(@path), params: { from: "dashboard" }, as: :turbo_stream

    assert_select "turbo-stream[action=replace][target=learning_path_cards] template", text: /No paths yet/
  end

  test "the dashboard card has delete, and failed paths have try again" do
    sign_in_as users(:two)
    docker = learning_paths(:docker)

    get dashboard_path

    assert_select "##{dom_id(docker, :card)}" do
      assert_select "form[action=?] button", regenerate_learning_path_path(docker), text: "Try again"
      assert_select "form[action=?] input[name=from][value=dashboard]", learning_path_path(docker)
      assert_select "button[aria-label='Delete Docker'][data-turbo-confirm]", text: "Delete"
    end
  end

  test "other people's paths can't be regenerated or deleted" do
    docker = learning_paths(:docker)

    assert_no_enqueued_jobs do
      post regenerate_learning_path_path(docker)
    end
    assert_response :not_found

    assert_no_difference "LearningPath.count" do
      delete learning_path_path(docker)
    end
    assert_response :not_found
    assert docker.reload.failed?
  end
end
