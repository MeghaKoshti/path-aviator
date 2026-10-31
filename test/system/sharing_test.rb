require "application_system_test_case"

class SharingTest < ApplicationSystemTestCase
  test "sharing a path, copying the link and turning sharing off" do
    path = learning_paths(:rails)
    sign_in_through_ui users(:one)
    visit learning_path_path(path)

    click_on "Create share link"
    assert_text "Share link created."
    link = shared_path_url(path.reload.share_token, host: Capybara.current_session.server.host, port: Capybara.current_session.server.port)
    assert_equal link, find_field("Share link", readonly: true).value

    # Let the page use the clipboard, as a person clicking the button would.
    page.driver.browser.execute_cdp("Browser.grantPermissions", permissions: %w[clipboardReadWrite clipboardSanitizedWrite])
    click_on "Copy link"
    assert_selector "#share [role=status]", text: "Link copied."
    assert_equal link, evaluate_async_script("navigator.clipboard.readText().then(arguments[0])")

    accept_confirm(/stop working/) { click_on "Stop sharing" }
    assert_text "Sharing is off. The link no longer works."
    assert_button "Create share link"
    assert_nil path.reload.share_token
  end
end
