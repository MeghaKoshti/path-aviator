require "test_helper"

class LinkBadgesTest < ActionView::TestCase
  helper LearningPathsHelper

  setup do
    @step = path_steps(:rails_models)
  end

  test "an unchecked link shows just the link" do
    render "path_steps/resource", path_step: @step

    assert_select "#resource_path_step_#{@step.id} a[href='#{@step.resource_url}']", /Read the docs/
    assert_select "#resource_path_step_#{@step.id}", text: /Link checked|verify|broken/, count: 0
  end

  test "a working link shows when it was checked" do
    @step.update!(link_status: :ok, link_checked_at: Time.zone.local(2026, 10, 24, 9))
    render "path_steps/resource", path_step: @step

    assert_select "a[href='#{@step.resource_url}']"
    assert_select "span[title*='24 October 2026']", text: /Link checked 24 Oct/
  end

  test "a link the site wouldn't let us check says so quietly" do
    @step.update!(link_status: :unverified, link_checked_at: Time.current)
    render "path_steps/resource", path_step: @step

    assert_select "a[href='#{@step.resource_url}']", /Read the docs/
    assert_select "span", text: /Couldn’t verify link/
  end

  test "a broken link offers a search instead and keeps the original as a fallback" do
    @step.update!(link_status: :broken, link_checked_at: Time.current)
    render "path_steps/resource", path_step: @step

    assert_select "p", text: /Link may be broken\./
    assert_select "a[href=?]", "https://www.google.com/search?q=Active+Record+basics+Ruby+on+Rails", text: /Search instead/
    assert_select "a[href='#{@step.resource_url}'][rel~=nofollow]", text: /try the original/
    assert_select "a", text: /Read the docs/, count: 0
  end

  test "the public share page shows the badges too" do
    @step.update!(link_status: :ok, link_checked_at: Time.current)
    render "path_steps/path_step", path_step: @step, up_next: false, last: false, read_only: true

    assert_select "span", text: /Link checked/
  end
end
