require "test_helper"

class JobPostPathsTest < ActionDispatch::IntegrationTest
  setup do
    @path = learning_paths(:rails)
    @path.update!(skills: [ "Ruby on Rails", "PostgreSQL" ])
    @path.learning_goal.update!(job_post: "Secret job post text from Acme", target_date: 4.weeks.from_now.to_date)
  end

  test "the owner sees the skills, the finish date and the pace" do
    sign_in_as users(:one)
    get learning_path_path(@path)

    assert_select "h2", "Skills this covers"
    assert_select "li", "Ruby on Rails"
    assert_select "span", /\AFinish by /
    assert_select "##{ActionView::RecordIdentifier.dom_id(@path, :progress)}", /On track/
    assert_no_match "Secret job post text", response.body
  end

  test "the public page shows the skills but never the job post" do
    @path.share!
    get shared_path_path(@path.share_token)

    assert_select "li", "PostgreSQL"
    assert_no_match "Secret job post text", response.body
  end

  test "the dashboard's weekly stats say whether each dated path is on track" do
    sign_in_as users(:one)
    get dashboard_path

    assert_select "ul[aria-label='Paths with a finish date'] li", 1 do
      assert_select "span", "On track"
      assert_select "a", @path.title
    end
  end
end
