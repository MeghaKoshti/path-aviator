require "test_helper"

class Admin::DashboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @previous = ENV["ADMIN_EMAILS"]
    ENV["ADMIN_EMAILS"] = " Two@Example.com , boss@example.com"
  end

  teardown { ENV["ADMIN_EMAILS"] = @previous }

  test "signed-out visitors get a plain 404" do
    get admin_root_path
    assert_response :not_found
  end

  test "signed-in non-admins get a 404 too" do
    sign_in_as users(:one)
    get admin_root_path

    assert_response :not_found
    assert_no_match "Admin", response.body.scan(/<h1.*?<\/h1>/m).join
  end

  test "the demo account is never an admin" do
    demo = DemoAccount.reset!
    ENV["ADMIN_EMAILS"] = DemoAccount.email
    sign_in_as demo, password: DemoAccount::PASSWORD

    get admin_root_path
    assert_response :not_found
  end

  test "admins see users, paths, generations, cost, the funnel and recent failures" do
    Event.track(:signed_up, user: users(:one))
    Event.track(:path_ready, user: users(:one), path_id: 1, estimated_tokens: 400_000)
    Event.track(:path_failed, user: users(:two), path_id: 3, error: "PathGenerator::Timeout: slow")
    sign_in_as users(:two)

    get admin_root_path

    assert_response :success
    assert_select "h1", "Admin"
    assert_select "dd", text: "2", minimum: 1 # users, and generations today
    assert_select "dd", "$0.60"
    assert_select "dt", "Failed"
    assert_select "li span", "two@example.com"
    assert_select "li p", "PathGenerator::Timeout: slow"
  end

  test "admins get an Admin link in the account menu" do
    sign_in_as users(:two)
    get dashboard_path
    assert_select "#account-menu a[href=?]", admin_root_path

    sign_in_as users(:one)
    get dashboard_path
    assert_select "a[href=?]", admin_root_path, count: 0
  end
end
