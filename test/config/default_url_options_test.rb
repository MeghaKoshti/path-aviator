require "test_helper"
require "turbo/broadcastable/test_helper"

# Broadcasts and emails are rendered outside a request, so their links take
# the host from the environment config instead of Rails' "example.org".
class DefaultUrlOptionsTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  test "a broadcast share link uses the app's host" do
    path = learning_paths(:rails)
    path.share!

    streams = capture_turbo_stream_broadcasts([ path.user, :learning_paths ]) { path.broadcast_refresh }

    assert_includes streams.first.to_html, "http://example.com/p/#{path.share_token}"
    assert_not_includes streams.first.to_html, "example.org"
  end

  test "renderer and mailer agree on the host" do
    assert_equal "http://example.com/p/abc", ApplicationController.render(inline: "<%= shared_path_url('abc') %>")
    assert_equal "example.com", ActionMailer::Base.default_url_options[:host]
  end
end
