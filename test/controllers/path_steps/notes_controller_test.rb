require "test_helper"

class PathSteps::NotesControllerTest < ActionDispatch::IntegrationTest
  FRAME = { "Turbo-Frame" => "note" }.freeze

  setup do
    sign_in_as users(:one)
    @step = path_steps(:rails_models)
    @path = learning_paths(:rails)
  end

  test "the path page shows saved notes and an add button for the rest" do
    get learning_path_path(@path)

    assert_select "turbo-frame##{dom_id(path_steps(:rails_intro), :note)}[data-turbo-permanent]" do
      assert_select "p", text: "Redo the blog with my own models."
      assert_select "a[href=?]", edit_path_step_note_path(path_steps(:rails_intro)), text: "Edit note for “Getting Started with Rails”"
    end
    assert_select "turbo-frame##{dom_id(@step, :note)} a[href=?]", edit_path_step_note_path(@step), text: "Add note for “Active Record basics”"
  end

  test "edit renders the note form inside the step's frame" do
    get edit_path_step_note_path(@step), headers: FRAME

    assert_response :success
    assert_select "turbo-frame##{dom_id(@step, :note)} form[action=?][data-controller=note-editor]", path_step_note_path(@step) do
      assert_select "textarea[name='path_step[note]'][maxlength='2000'][autofocus]"
      assert_select "label", text: "Your note for “Active Record basics”"
      assert_select "input[type=submit][value='Save note']"
      assert_select "a[href=?][data-note-editor-target=cancel]", path_step_note_path(@step), text: "Cancel"
    end
  end

  test "saving in the frame returns the note, escaped, with focus on its edit button" do
    patch path_step_note_path(@step), params: { path_step: { note: "  Try <script>alert(1)</script> in the console  " } }, headers: FRAME

    assert_response :success
    assert_equal "Try <script>alert(1)</script> in the console", @step.reload.note
    assert_includes response.body, "Try &lt;script&gt;alert(1)&lt;/script&gt; in the console"
    assert_not_includes response.body, "<script>alert(1)"
    assert_select "turbo-frame##{dom_id(@step, :note)} a[autofocus][href=?]", edit_path_step_note_path(@step)
  end

  test "saving without JavaScript goes back to the step" do
    patch path_step_note_path(@step), params: { path_step: { note: "Read twice." } }

    assert_redirected_to learning_path_path(@path, anchor: dom_id(@step))
    assert_equal "Read twice.", @step.reload.note
  end

  test "saving an empty note removes it" do
    step = path_steps(:rails_intro)

    patch path_step_note_path(step), params: { path_step: { note: "   " } }, headers: FRAME

    assert_nil step.reload.note
    assert_select "a", text: /Add note/
  end

  test "a note over 2,000 characters is refused with a message" do
    patch path_step_note_path(@step), params: { path_step: { note: "a" * 2_001 } }, headers: FRAME

    assert_response :unprocessable_entity
    assert_nil @step.reload.note
    assert_select "textarea[aria-invalid=true]"
    assert_select "p", text: /too long/
  end

  test "cancel shows the note again; without JavaScript it returns to the path" do
    get path_step_note_path(@step), headers: FRAME
    assert_select "turbo-frame##{dom_id(@step, :note)} a[autofocus]", text: /Add note/

    get path_step_note_path(@step)
    assert_redirected_to learning_path_path(@path, anchor: dom_id(@step))
  end

  test "another user's step notes are not found" do
    sign_in_as users(:two)
    step = path_steps(:rails_intro)

    get edit_path_step_note_path(step)
    assert_response :not_found
    get path_step_note_path(step), headers: FRAME
    assert_response :not_found
    patch path_step_note_path(step), params: { path_step: { note: "Hijacked" } }
    assert_response :not_found

    assert_equal "Redo the blog with my own models.", step.reload.note
  end

  test "requires sign-in" do
    delete session_path

    patch path_step_note_path(@step), params: { path_step: { note: "Hi" } }

    assert_redirected_to new_session_path
    assert_nil @step.reload.note
  end
end
