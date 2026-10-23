require "application_system_test_case"

class PathManagementSystemTest < ApplicationSystemTestCase
  test "deleting a path from the dashboard removes its card in place" do
    path = learning_paths(:rails)
    sign_in_through_ui users(:one)
    assert_selector "##{dom_id(path, :card)}"

    accept_confirm(/gone for good/) do
      within("##{dom_id(path, :card)}") { click_on "Delete" }
    end

    assert_no_selector "##{dom_id(path, :card)}"
    assert_text "Deleted “#{path.title}”"
    assert_text "1 path, 0 complete."
    # Focus moves to the page heading instead of being lost with the card.
    assert_equal "Your learning paths", evaluate_script("document.activeElement.textContent").strip
    assert_current_path dashboard_path
  end

  test "regenerating a ready path asks first, then shows the planning state" do
    path = learning_paths(:rails)
    sign_in_through_ui users(:one)
    visit learning_path_path(path)

    dismiss_confirm { click_on "Regenerate" }
    assert_text "1 of 4"

    accept_confirm { click_on "Regenerate" }
    assert_selector "h1", text: "Charting your route to Ruby on Rails"
    assert path.reload.generating?
  end

  test "a path that finished while the stream wasn't listening still shows up" do
    path = learning_paths(:sql)
    sign_in_through_ui users(:one)
    visit learning_path_path(path)
    assert_selector "turbo-cable-stream-source[connected]", visible: :all
    assert_selector "h1", text: "Charting your route to SQL for analytics"

    # The job finishes without anyone hearing the broadcast...
    path.update!(status: :ready, title: "SQL for analytics, planned")
    # ...and the stream reconnects. The page should catch up well before the 20s fallback.
    execute_script <<~JS
      const source = document.querySelector("turbo-cable-stream-source")
      source.removeAttribute("connected")
      source.setAttribute("connected", "")
    JS

    assert_selector "h1", text: "SQL for analytics, planned"
  end
end
