# Checks that a step's link opens a real page, without ever letting a
# generated URL reach something inside our own network (SSRF).
#
#   LinkChecker.new.check("https://guides.rubyonrails.org/") # => Result(status: :ok, ...)
#
# Every hop (the first URL and each redirect) is checked the same way: only
# http(s) on ports 80/443, the host is resolved here and every address must be
# public, and the connection then goes to that vetted address (so a second DNS
# answer can't swap in an internal one). At most 3 redirects, HEAD first and GET
# when HEAD isn't answered properly, 5 seconds per request.
#
# How answers are read:
# - ok:         2xx at the end of the redirects.
# - unverified: the site answered but wouldn't let a bot in (401, 403, 429, 999)
#               or had a passing problem (5xx, timeout, reset). Big sites such as
#               LinkedIn, Medium, Udemy and anything behind Cloudflare often send
#               403/429 to anything that isn't a browser, so these count as
#               "probably fine": shown as not verified, never replaced.
# - broken:     404, 410 and other 4xx, unknown host, refused connection, TLS
#               errors, redirect loops or too many redirects, non-http(s) links,
#               and anything that points at a private, loopback, link-local or
#               cloud-metadata address.
class LinkChecker
  MAX_REDIRECTS = 3
  ALLOWED_PORTS = [ 80, 443 ].freeze
  NOT_VERIFIABLE = [ 401, 403, 429, 999 ].freeze # 999 is LinkedIn's "no bots"

  class Error < StandardError; end
  class Timeout < Error; end
  class ConnectionFailed < Error; end
  class ConnectionReset < Error; end
  class Blocked < Error; end

  Result = Data.define(:status, :http_status, :final_url, :reason) do
    def ok? = status == :ok
    def broken? = status == :broken
  end

  class << self
    attr_writer :default

    # Tests never touch the network; everywhere else checks for real.
    def default
      @default || (Rails.env.test? ? Fake.new : new)
    end
  end

  def initialize(transport: HttpTransport.new, resolver: Resolver.new)
    @transport = transport
    @resolver = resolver
  end

  def check(url)
    uri = parse(url)
    return result(:broken, uri, reason: "not an http(s) link") unless uri

    seen = []
    (MAX_REDIRECTS + 1).times do
      return result(:broken, uri, reason: "redirect loop") if seen.include?(uri.to_s)

      seen << uri.to_s
      response = fetch(uri, public_address(uri))
      return read(response, uri) unless response.redirect?

      next_uri = parse(URI.join(uri.to_s, response.location).to_s)
      return result(:broken, uri, http_status: response.status, reason: "redirects to a non-http(s) address") unless next_uri

      uri = next_uri
    end

    result(:broken, uri, reason: "more than #{MAX_REDIRECTS} redirects")
  rescue Timeout, ConnectionReset => e
    result(:unverified, uri, reason: e.message)
  rescue Blocked, ConnectionFailed, URI::Error => e
    result(:broken, uri, reason: e.message)
  end

  private
    # HEAD is cheap, but plenty of servers answer it with 403, 404 or 405
    # while GET works, so anything that isn't a success or redirect is retried.
    def fetch(uri, address)
      response = @transport.request(:head, uri, address: address)
      return response if response.success? || response.redirect?

      @transport.request(:get, uri, address: address)
    end

    def read(response, uri)
      status = response.status
      if response.success?
        result(:ok, uri, http_status: status)
      elsif NOT_VERIFIABLE.include?(status) || status >= 500
        result(:unverified, uri, http_status: status, reason: "HTTP #{status}")
      else
        result(:broken, uri, http_status: status, reason: "HTTP #{status}")
      end
    end

    def parse(url)
      uri = URI.parse(url.to_s.strip)
      return unless uri.is_a?(URI::HTTP) && uri.host.present? && ALLOWED_PORTS.include?(uri.port)
      return if uri.userinfo.present? # user:pass@ links are never what a learner needs

      uri
    rescue URI::InvalidURIError
      nil
    end

    # Every address the name resolves to must be public, otherwise a host with
    # one public and one internal record could still reach the internal one.
    def public_address(uri)
      addresses = @resolver.addresses(uri.hostname)
      raise Blocked, "host not found" if addresses.empty?
      raise Blocked, "points at a private or internal address" if addresses.any? { |address| IpPolicy.blocked?(address) }

      addresses.first
    end

    def result(status, uri, http_status: nil, reason: nil)
      Result.new(status:, http_status:, final_url: uri&.to_s, reason:)
    end
end
