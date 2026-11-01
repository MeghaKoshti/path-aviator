require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "tracks known events with properties" do
    event = Event.track(:path_ready, user: users(:one), path_id: 5)

    assert_equal "path_ready", event.name
    assert_equal({ "path_id" => 5 }, event.reload.properties)
  end

  test "unknown names are refused without raising" do
    assert_no_difference(-> { Event.count }) { assert_nil Event.track(:clicked_everything, user: users(:one)) }
  end

  test "track_once records a milestone only the first time" do
    assert_difference(-> { Event.count }, 1) do
      3.times { Event.track_once(:first_step_done, user: users(:one)) }
    end
  end

  test "events stay when the account is deleted, without the user" do
    event = Event.track(:signed_up, user: users(:two))
    users(:two).destroy!

    assert_nil event.reload.user_id
  end
end
