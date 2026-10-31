require "net/http"

module Billing
  # Small JSON-over-HTTPS client for provider APIs. Adapters take it as a
  # dependency so tests pass a stand-in and never touch the network.
  class HttpClient
    Response = Data.define(:status, :body) do
      def success? = status.between?(200, 299)
      def json = JSON.parse(body)
    end

    def initialize(open_timeout: 5, read_timeout: 15)
      @open_timeout = open_timeout
      @read_timeout = read_timeout
    end

    def post_json(url, body:, headers: {})
      uri = URI(url)
      options = { use_ssl: uri.scheme == "https", open_timeout: @open_timeout, read_timeout: @read_timeout, write_timeout: @read_timeout }

      Net::HTTP.start(uri.host, uri.port, **options) do |http|
        request = Net::HTTP::Post.new(uri, { "Content-Type" => "application/json", "Accept" => "application/json" }.merge(headers))
        request.body = body
        response = http.request(request)
        Response.new(status: response.code.to_i, body: response.body.to_s)
      end
    rescue ::Timeout::Error, SocketError, SystemCallError, IOError, OpenSSL::SSL::SSLError => e
      raise RequestFailed, "#{uri.host} request failed (#{e.class})"
    end
  end
end
