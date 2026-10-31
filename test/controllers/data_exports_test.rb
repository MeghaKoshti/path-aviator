require "test_helper"
require "turbo/broadcastable/test_helper"

class DataExportsTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include Turbo::Broadcastable::TestHelper

  setup { sign_in_as users(:one) }

  test "settings offers to prepare the data" do
    get settings_path
    assert_select "#data_export form[action=?] button", settings_data_export_path, text: "Prepare my data"
  end

  test "preparing builds the archive in a job and the page then offers the download" do
    assert_enqueued_with(job: DataExportJob) { post settings_data_export_path }
    assert_redirected_to settings_path(anchor: "data_export")
    follow_redirect!
    assert_select "#data_export", /Preparing your data/

    streams = capture_turbo_stream_broadcasts([ users(:one), :data_exports ]) { perform_enqueued_jobs }
    assert_includes streams.sole.to_html, "Download my data"
    assert users(:one).data_exports.sole.ready?

    get settings_data_export_path
    assert_response :success
    assert_equal "application/gzip", response.media_type
    assert_match(/attachment; filename="path-aviator-export-\d{4}-\d{2}-\d{2}\.tar\.gz"/, response.headers["Content-Disposition"])
  end

  test "a new export replaces the previous one" do
    2.times { post settings_data_export_path }
    assert_equal 1, users(:one).data_exports.count
  end

  test "there is nothing to download before an export is ready, and never someone else's" do
    users(:two).data_exports.create!(status: :ready, archive: "theirs")

    get settings_data_export_path
    assert_response :not_found
  end
end
