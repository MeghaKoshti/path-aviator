require "test_helper"

class PathGenerator::ValidatorTest < ActiveSupport::TestCase
  def step(**overrides)
    { "title" => "Read the guide", "description" => "Basics.", "resource_type" => "docs",
      "resource_url" => "https://guides.rubyonrails.org", "estimated_minutes" => 30 }.merge(overrides.stringify_keys)
  end

  def data(steps: Array.new(6) { step }, **overrides)
    { "title" => "Path", "summary" => "Summary", "steps" => steps }.merge(overrides.stringify_keys)
  end

  def errors_for(payload)
    PathGenerator::Validator.new(payload).errors
  end

  test "accepts a well formed path" do
    assert PathGenerator::Validator.new(data).valid?
  end

  test "requires between 6 and 12 steps" do
    assert_not_empty errors_for(data(steps: Array.new(5) { step }))
    assert_not_empty errors_for(data(steps: Array.new(13) { step }))
    assert_empty errors_for(data(steps: Array.new(12) { step }))
    assert_not_empty errors_for(data(steps: nil))
  end

  test "requires title and summary" do
    assert_includes errors_for(data(title: "")), "title is missing"
    assert_includes errors_for(data(summary: nil)), "summary is missing"
  end

  test "requires every step field" do
    %w[title description resource_type resource_url].each do |field|
      steps = Array.new(6) { step }
      steps[2] = step.except(field)
      assert_includes errors_for(data(steps:)), "step 3 #{field} is missing"
    end
  end

  test "rejects unknown resource types" do
    steps = Array.new(6) { step(resource_type: "podcast") }
    assert_includes errors_for(data(steps:)), %(step 1 resource_type "podcast" is not allowed)
  end

  test "resource type check ignores case" do
    assert_empty errors_for(data(steps: Array.new(6) { step(resource_type: " Video ") }))
  end

  test "rejects non-http urls" do
    steps = Array.new(6) { step(resource_url: "javascript:alert(1)") }
    assert_includes errors_for(data(steps:)), "step 1 resource_url must be http(s)"
  end

  test "requires minutes to be a positive integer" do
    [ 0, -10, 12.5, "30", nil ].each do |minutes|
      steps = Array.new(6) { step(estimated_minutes: minutes) }
      assert_includes errors_for(data(steps:)), "step 1 estimated_minutes must be a positive integer", minutes.inspect
    end
  end

  test "rejects steps that are not objects" do
    assert_includes errors_for(data(steps: Array.new(6) { "step" })), "step 1 is not an object"
  end
end
