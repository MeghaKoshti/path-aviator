require "application_system_test_case"

class StepNotesTest < ApplicationSystemTestCase
  test "adding, cancelling and editing a note in place, and keeping it through ticks" do
    path = learning_paths(:rails)
    step = path_steps(:rails_models)
    sign_in_through_ui users(:one)
    visit learning_path_path(path)
    execute_script "window.stillHere = true"

    within("##{dom_id(step)}") do
      click_on "Add note"
      find("textarea").fill_in with: "Not saved"
      find("textarea").send_keys :escape

      assert_no_selector "textarea"
      assert_no_text "Not saved"
      assert_equal "Add note for “Active Record basics”", evaluate_script("document.activeElement.textContent").squish

      click_on "Add note"
      fill_in "Your note for “Active Record basics”", with: "Focus on validations.\nSkip callbacks for now."
      click_on "Save note"

      assert_text "Your note"
      assert_text "Focus on validations."
      assert_equal "Edit note for “Active Record basics”", evaluate_script("document.activeElement.textContent").squish
    end
    assert_equal "Focus on validations.\nSkip callbacks for now.", step.reload.note

    # Ticking re-renders the whole route; the saved note and an open,
    # half-written editor on another step both survive it.
    within("##{dom_id(path_steps(:rails_hotwire))}") do
      click_on "Add note"
      find("textarea").fill_in with: "Half written"
    end
    find("##{dom_id(step, :toggle)}").click
    assert_selector "##{dom_id(step, :toggle)}[aria-checked=true]"
    within("##{dom_id(step)}") { assert_text "Focus on validations." }
    within("##{dom_id(path_steps(:rails_hotwire))}") { assert_equal "Half written", find("textarea").value }

    find("##{dom_id(step, :toggle)}").click
    assert_selector "##{dom_id(step, :toggle)}[aria-checked=false]"
    within("##{dom_id(step)}") { assert_text "Focus on validations." }
    assert evaluate_script("window.stillHere"), "the page reloaded"
  end
end
