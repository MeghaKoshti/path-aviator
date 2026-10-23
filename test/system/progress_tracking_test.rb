require "application_system_test_case"

class ProgressTrackingTest < ApplicationSystemTestCase
  test "ticking a step updates progress without a page reload" do
    path = learning_paths(:rails)
    sign_in_through_ui users(:one)

    within "##{dom_id(path, :card)}" do
      assert_text "25%"
      click_on "Continue"
    end
    assert_current_path learning_path_path(path)

    within "##{dom_id(path, :progress)}" do
      assert_text "1 of 4"
      assert_text "3 h 45 min"
    end
    # Only a full page load clears this, Turbo updates keep it.
    execute_script "window.stillHere = true"

    checkbox = find("##{dom_id(path_steps(:rails_models), :toggle)}")
    assert_equal "false", checkbox["aria-checked"]
    checkbox.click

    within "##{dom_id(path, :progress)}" do
      assert_text "2 of 4"
      assert_text "2 h 45 min"
      assert_selector "progress[value='50']"
      assert_link "Hotwire walkthrough"
    end
    assert_selector "##{dom_id(path_steps(:rails_models), :toggle)}[aria-checked=true]"
    assert_selector "#path-announcer", text: "Marked “Active Record basics” as done.", visible: :all
    assert evaluate_script("window.stillHere"), "the page reloaded"
    assert path_steps(:rails_models).reload.completed?
  end
end
