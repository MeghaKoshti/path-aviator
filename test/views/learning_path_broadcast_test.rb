require "test_helper"
require "turbo/broadcastable/test_helper"

# The generation job re-renders the path partial outside any request and
# broadcasts it. These tests render it the same way for every status.
class LearningPathBroadcastTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper
  include ActionView::RecordIdentifier

  test "a ready path broadcasts its steps to the owner's stream" do
    path = learning_paths(:rails)

    html = broadcast_html(path)

    assert_includes html, %(<turbo-stream action="replace" target="#{dom_id(path)}">)
    assert_includes html, path.title
    assert_includes html, "Getting Started with Rails"
    assert_includes html, %(data-path-status-status-value="ready")
  end

  test "a generating path broadcasts the waiting state" do
    html = broadcast_html(learning_paths(:sql))

    assert_includes html, "Charting your route to SQL for analytics"
    assert_includes html, %(data-path-status-status-value="generating")
  end

  test "a failed path broadcasts the retry button" do
    path = learning_paths(:docker)

    html = broadcast_html(path)

    assert_includes html, "We couldn’t plan your route to Docker"
    assert_includes html, "/learning_paths/#{path.id}/regenerate"
  end

  private
    def broadcast_html(path)
      broadcasts = capture_turbo_stream_broadcasts([ path.user, :learning_paths ]) { path.broadcast_refresh }
      assert_equal 1, broadcasts.size
      broadcasts.first.to_html
    end
end
