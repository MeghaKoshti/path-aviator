require "test_helper"
require "minitest/mock"

class PathGenerator::HttpClientTest < ActiveSupport::TestCase
  # Stands in for the Net::HTTP connection yielded by Net::HTTP.start.
  class FakeConnection
    attr_reader :last_request

    def initialize(response)
      @response = response
    end

    def request(request)
      @last_request = request
      @response
    end
  end

  def net_response(code, body)
    Net::HTTPResponse::CODE_TO_OBJ[code.to_s].new("1.1", code.to_s, "").tap do |response|
      response.instance_variable_set(:@read, true)
      response.instance_variable_set(:@body, body)
    end
  end

  test "posts JSON and wraps the response" do
    connection = FakeConnection.new(net_response(200, '{"ok":true}'))
    start_args = nil
    fake_start = ->(*args, **options, &block) { start_args = [ args, options ]; block.call(connection) }

    response = Net::HTTP.stub(:start, fake_start) do
      PathGenerator::HttpClient.new(read_timeout: 7).post_json("https://api.example.com/v1/run", body: "{}", headers: { "x-key" => "abc" })
    end

    assert response.success?
    assert_equal '{"ok":true}', response.body
    assert_equal [ "api.example.com", 443 ], start_args.first
    assert_equal({ use_ssl: true, open_timeout: 5, read_timeout: 7, write_timeout: 7 }, start_args.last)
    assert_equal "POST", connection.last_request.method
    assert_equal "/v1/run", connection.last_request.path
    assert_equal "abc", connection.last_request["x-key"]
    assert_equal "application/json", connection.last_request["Content-Type"]
    assert_equal "{}", connection.last_request.body
  end

  test "reports non-2xx responses as unsuccessful" do
    connection = FakeConnection.new(net_response(500, "oops"))
    response = Net::HTTP.stub(:start, ->(*, **, &block) { block.call(connection) }) do
      PathGenerator::HttpClient.new.post_json("https://api.example.com", body: "{}")
    end

    assert_not response.success?
    assert_equal 500, response.status
  end

  test "turns read and open timeouts into PathGenerator::Timeout" do
    [ Net::ReadTimeout, Net::OpenTimeout ].each do |error|
      Net::HTTP.stub(:start, ->(*, **) { raise error }) do
        assert_raises(PathGenerator::Timeout) do
          PathGenerator::HttpClient.new.post_json("https://api.example.com", body: "{}")
        end
      end
    end
  end

  test "turns connection errors into PathGenerator::RequestFailed" do
    Net::HTTP.stub(:start, ->(*, **) { raise Errno::ECONNREFUSED }) do
      assert_raises(PathGenerator::RequestFailed) do
        PathGenerator::HttpClient.new.post_json("https://api.example.com", body: "{}")
      end
    end
  end
end
