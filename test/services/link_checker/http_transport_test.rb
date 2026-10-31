require "test_helper"
require "socket"

# Talks to a throwaway server on 127.0.0.1, so no outside network is used.
class LinkChecker::HttpTransportTest < ActiveSupport::TestCase
  # Accepts one connection, records the request head and replies with `reply`
  # (or nothing at all when reply is nil, to cause a timeout).
  def serve(reply)
    server = TCPServer.new("127.0.0.1", 0)
    request = +""
    thread = Thread.new do
      client = server.accept
      while (line = client.gets) && line != "\r\n"
        request << line
      end
      if reply
        client.write(reply)
      else
        sleep 2
      end
      client.close
    rescue IOError, SystemCallError
      nil
    end
    yield server.addr[1], -> { thread.join(3); request }
  ensure
    server&.close
    thread&.kill
  end

  test "connects to the vetted address while sending the real host name and a polite user agent" do
    serve("HTTP/1.1 301 Moved\r\nLocation: /new\r\nContent-Length: 0\r\n\r\n") do |port, request|
      # The name doesn't resolve anywhere: only the given address is used.
      uri = URI("http://docs.not-a-real-host.test:#{port}/guide")
      response = LinkChecker::HttpTransport.new.request(:head, uri, address: "127.0.0.1")

      assert_equal 301, response.status
      assert_equal "/new", response.location
      assert response.redirect?
      assert_match %r{\AHEAD /guide HTTP/1.1}, request.call
      assert_match "Host: docs.not-a-real-host.test:#{port}", request.call
      assert_match "User-Agent: #{LinkChecker::HttpTransport::USER_AGENT}", request.call
    end
  end

  test "a GET reads only the start of a big page" do
    body = "x" * 5_000_000
    serve("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: #{body.bytesize}\r\n\r\n#{body}") do |port, _request|
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response = LinkChecker::HttpTransport.new.request(:get, URI("http://big.test:#{port}/"), address: "127.0.0.1")

      assert response.success?
      assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 2
    end
  end

  test "a server that never answers times out" do
    serve(nil) do |port, _request|
      assert_raises(LinkChecker::Timeout) do
        LinkChecker::HttpTransport.new(timeout: 0.3).request(:head, URI("http://slow.test:#{port}/"), address: "127.0.0.1")
      end
    end
  end

  test "a refused connection fails" do
    port = TCPServer.open("127.0.0.1", 0) { |server| server.addr[1] } # closed again, so nothing listens

    assert_raises(LinkChecker::ConnectionFailed) do
      LinkChecker::HttpTransport.new.request(:head, URI("http://closed.test:#{port}/"), address: "127.0.0.1")
    end
  end
end
