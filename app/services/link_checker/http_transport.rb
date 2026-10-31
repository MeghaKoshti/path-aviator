require "net/http"

class LinkChecker
  # One HEAD or GET to an address LinkChecker has already vetted. Redirects are
  # not followed here: LinkChecker checks each hop itself.
  class HttpTransport
    USER_AGENT = "Mozilla/5.0 (compatible; PathAviatorLinkChecker/1.0; +https://github.com/MeghaKoshti/path-aviator)".freeze
    BODY_LIMIT = 16 * 1024 # bytes; only the status matters, so a GET reads a little and hangs up

    Response = Data.define(:status, :location) do
      def success? = status.between?(200, 299)
      def redirect? = status.between?(300, 399) && location.present?
    end

    def initialize(timeout: 5)
      @timeout = timeout
    end

    def request(method, uri, address:)
      # No proxy (nil), even if one is set in ENV: a proxy would resolve the
      # name again itself and undo the address check.
      http = Net::HTTP.new(uri.host, uri.port, nil)
      http.ipaddr = address # connect here; Host header and TLS name stay uri.host
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = http.read_timeout = http.write_timeout = http.ssl_timeout = @timeout

      http.start do
        request = (method == :head ? Net::HTTP::Head : Net::HTTP::Get).new(uri, "User-Agent" => USER_AGENT, "Accept" => "text/html,*/*;q=0.8")
        http.request(request) do |response|
          read_a_little(response) if method == :get
          return Response.new(status: response.code.to_i, location: response["location"])
        end
      end
    rescue ::Timeout::Error => e # covers Net::OpenTimeout and Net::ReadTimeout
      raise LinkChecker::Timeout, "timed out (#{e.class})"
    rescue Errno::ECONNRESET, EOFError => e
      raise LinkChecker::ConnectionReset, "connection reset (#{e.class})"
    rescue SocketError, SystemCallError, IOError, OpenSSL::SSL::SSLError => e
      raise LinkChecker::ConnectionFailed, "connection failed (#{e.class})"
    end

    private
      def read_a_little(response)
        read = 0
        response.read_body do |chunk|
          read += chunk.bytesize
          break if read >= BODY_LIMIT
        end
      end
  end
end
