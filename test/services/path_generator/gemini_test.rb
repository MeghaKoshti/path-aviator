require "test_helper"

class PathGenerator::GeminiTest < ActiveSupport::TestCase
  # Records the request and replies with a canned response instead of using the network.
  class FakeHttp
    attr_reader :url, :body, :headers

    def initialize(status: 200, body: nil, error: nil)
      @response = PathGenerator::HttpClient::Response.new(status:, body:)
      @error = error
    end

    def post_json(url, body:, headers:)
      @url, @body, @headers = url, JSON.parse(body), headers
      raise @error if @error

      @response
    end
  end

  setup do
    @goal = learning_goals(:rails)
  end

  def envelope(text)
    { candidates: [ { content: { parts: [ { text: text } ] } } ] }.to_json
  end

  test "posts the prompt to the configured model and returns the model's text" do
    http = FakeHttp.new(body: envelope('{"title":"x"}'))
    client = PathGenerator::Gemini.new(api_key: "secret", model: "gemini-test", http: http)

    assert_equal '{"title":"x"}', client.generate(@goal)
    assert_equal "https://generativelanguage.googleapis.com/v1beta/models/gemini-test:generateContent", http.url
    assert_equal "secret", http.headers["x-goog-api-key"]
    assert_equal "application/json", http.body.dig("generationConfig", "responseMimeType")
    assert_includes http.body.dig("contents", 0, "parts", 0, "text"), "Ruby on Rails"
  end

  test "defaults to gemini-2.5-flash" do
    http = FakeHttp.new(body: envelope("{}"))
    PathGenerator::Gemini.new(api_key: "k", model: nil, http: http).generate(@goal)
    assert_includes http.url, "/models/gemini-2.5-flash:"
  end

  test "prompt includes topic, level, weekly hours and the learner's goal" do
    prompt = PathGenerator::Gemini.new(api_key: "k", http: FakeHttp.new).prompt_for(@goal)

    assert_includes prompt, "Topic: Ruby on Rails"
    assert_includes prompt, "Current level: beginner"
    assert_includes prompt, "6 hours per week"
    assert_includes prompt, @goal.goal_description
    assert_includes prompt, "STRICT JSON"
  end

  test "raises RequestFailed for HTTP errors" do
    client = PathGenerator::Gemini.new(api_key: "k", http: FakeHttp.new(status: 503, body: "busy"))
    assert_raises(PathGenerator::RequestFailed) { client.generate(@goal) }
  end

  test "raises InvalidOutput when the response has no text" do
    client = PathGenerator::Gemini.new(api_key: "k", http: FakeHttp.new(body: { candidates: [] }.to_json))
    assert_raises(PathGenerator::InvalidOutput) { client.generate(@goal) }
  end

  test "raises InvalidOutput when the envelope is not JSON" do
    client = PathGenerator::Gemini.new(api_key: "k", http: FakeHttp.new(body: "<html>"))
    assert_raises(PathGenerator::InvalidOutput) { client.generate(@goal) }
  end

  test "passes timeouts through" do
    client = PathGenerator::Gemini.new(api_key: "k", http: FakeHttp.new(error: PathGenerator::Timeout.new("slow")))
    assert_raises(PathGenerator::Timeout) { client.generate(@goal) }
  end

  test "is the default client when a key is set outside tests" do
    Rails.env.stub(:test?, false) do
      with_env("GEMINI_API_KEY" => "k") { assert_instance_of PathGenerator::Gemini, PathGenerator.client }
      with_env("GEMINI_API_KEY" => nil) { assert_instance_of PathGenerator::Fake, PathGenerator.client }
    end
  end

  private
    def with_env(vars)
      old = vars.keys.to_h { |key| [ key, ENV[key] ] }
      vars.each { |key, value| ENV[key] = value }
      yield
    ensure
      old.each { |key, value| ENV[key] = value }
    end
end
