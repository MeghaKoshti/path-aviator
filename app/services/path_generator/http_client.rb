require "net/http"

module PathGenerator
  # A tiny Net::HTTP wrapper. Clients take it as a dependency so tests can
  # pass a stand-in object instead of hitting the network.
  class HttpClient
    Response = Data.define(:status, :body) do
      def success? = status.between?(200, 299)
    end

    def initialize(open_timeout: 5, read_timeout: 20)
      @open_timeout = open_timeout
      @read_timeout = read_timeout
    end

    def post_json(url, body:, headers: {})
      uri = URI(url)
      options = { use_ssl: uri.scheme == "https", open_timeout: @open_timeout, read_timeout: @read_timeout, write_timeout: @read_timeout }

      Net::HTTP.start(uri.host, uri.port, **options) do |http|
        request = Net::HTTP::Post.new(uri, { "Content-Type" => "application/json" }.merge(headers))
        request.body = body
        response = http.request(request)
        Response.new(status: response.code.to_i, body: response.body.to_s)
      end
    rescue ::Timeout::Error => e # Net::OpenTimeout, ReadTimeout and WriteTimeout inherit from it
      raise PathGenerator::Timeout, "#{uri.host} timed out (#{e.class})"
    rescue SocketError, SystemCallError, IOError, OpenSSL::SSL::SSLError => e
      raise PathGenerator::RequestFailed, "#{uri.host} request failed (#{e.class})"
    end
  end
end
