require "test_helper"

class PathStepTest < ActiveSupport::TestCase
  setup do
    @path = learning_paths(:rails)
  end

  def build_step(**attrs)
    @path.path_steps.new({
      position: 5, title: "Write tests", description: "Minitest basics.",
      resource_type: "article", resource_url: "https://guides.rubyonrails.org/testing.html",
      estimated_minutes: 30
    }.merge(attrs))
  end

  test "valid with all fields" do
    assert build_step.valid?
  end

  test "resource type must be one of the allowed kinds" do
    PathStep::RESOURCE_TYPES.each { |type| assert build_step(resource_type: type).valid?, type }
    assert_not build_step(resource_type: "podcast").valid?
  end

  test "resource url must be http or https" do
    assert build_step(resource_url: "http://example.com/a").valid?
    assert_not build_step(resource_url: "javascript:alert(1)").valid?
    assert_not build_step(resource_url: "ftp://example.com/file").valid?
    assert_not build_step(resource_url: "not a url").valid?
    assert_not build_step(resource_url: "").valid?
  end

  test "estimated minutes must be a positive whole number" do
    assert_not build_step(estimated_minutes: 0).valid?
    assert_not build_step(estimated_minutes: -5).valid?
    assert_not build_step(estimated_minutes: 1.5).valid?
  end

  test "position is unique within a path" do
    assert_not build_step(position: 1).valid?
  end

  test "creating steps updates the path counter caches" do
    assert_difference -> { @path.reload.path_steps_count } => 1, -> { @path.reload.completed_steps_count } => 1 do
      build_step(completed_at: Time.current).save!
    end
  end

  test "toggle_completion! marks a step done and bumps the path counter" do
    step = path_steps(:rails_models)

    assert_difference -> { @path.reload.completed_steps_count }, 1 do
      step.toggle_completion!
    end
    assert step.reload.completed?
  end

  test "toggle_completion! on a done step clears it and lowers the counter" do
    step = path_steps(:rails_intro)

    assert_difference -> { @path.reload.completed_steps_count }, -1 do
      step.toggle_completion!
    end
    assert_nil step.reload.completed_at
  end

  test "toggling back and forth keeps the counter matching the real count" do
    step = path_steps(:rails_hotwire)
    3.times { step.toggle_completion! }

    @path.reload
    assert_equal @path.path_steps.completed.count, @path.completed_steps_count
    assert_equal 2, @path.completed_steps_count
  end

  test "updating other fields of a done step does not change the counter" do
    step = path_steps(:rails_intro)
    assert_no_difference -> { @path.reload.completed_steps_count } do
      step.update!(title: "Renamed", completed_at: 1.minute.ago)
    end
  end

  test "destroying a done step lowers both counters" do
    assert_difference -> { @path.reload.path_steps_count } => -1, -> { @path.reload.completed_steps_count } => -1 do
      path_steps(:rails_intro).destroy
    end
  end

  test "a note is optional, trimmed, and at most 2,000 characters" do
    assert_nil build_step(note: "  \n ").note
    assert_equal "Watch at 1.5x", build_step(note: " Watch at 1.5x ").note
    assert build_step(note: "a" * 2_000).valid?
    assert_not build_step(note: "a" * 2_001).valid?
  end

  test "ticking and unticking a step keeps its note" do
    step = path_steps(:rails_intro)

    step.toggle_completion!
    step.toggle_completion!

    assert_equal "Redo the blog with my own models.", step.reload.note
  end
end
