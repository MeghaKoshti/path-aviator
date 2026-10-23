require "test_helper"

class PathStepsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @step = path_steps(:rails_models)
    @path = learning_paths(:rails)
  end

  test "ticking a step returns Turbo Streams for the route, progress and announcement" do
    patch toggle_path_step_path(@step), as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert @step.reload.completed?
    assert_equal 2, @path.reload.completed_steps_count
    assert_select "turbo-stream[action=replace][target=?][method=morph]", dom_id(@path, :steps)
    assert_select "turbo-stream[action=replace][target=?]", dom_id(@path, :progress) do
      assert_select "template", text: /2 of 4/
    end
    assert_select "turbo-stream[action=update][target=path-announcer] template", text: /Marked “Active Record basics” as done. 2 of 4 steps done./
    assert_select "turbo-stream template button##{dom_id(@step, :toggle)}[role=checkbox][aria-checked=true]"
  end

  test "ticking a done step marks it not done" do
    step = path_steps(:rails_intro)

    patch toggle_path_step_path(step), as: :turbo_stream

    assert_not step.reload.completed?
    assert_equal 0, @path.reload.completed_steps_count
    assert_select "turbo-stream[target=path-announcer] template", text: /as not done/
  end

  test "without Turbo it redirects back to the step" do
    patch toggle_path_step_path(@step)

    assert_redirected_to learning_path_path(@path, anchor: dom_id(@step))
    assert @step.reload.completed?
  end

  test "another user's step is not found and stays unchanged" do
    sign_in_as users(:two)

    patch toggle_path_step_path(@step), as: :turbo_stream

    assert_response :not_found
    assert_not @step.reload.completed?
  end

  test "requires sign-in" do
    delete session_path

    patch toggle_path_step_path(@step)

    assert_redirected_to new_session_path
    assert_not @step.reload.completed?
  end
end
