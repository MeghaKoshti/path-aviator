require "test_helper"

class LinkCheckerTest < ActiveSupport::TestCase
  Response = LinkChecker::HttpTransport::Response

  # Answers from a table: "METHOD url" (or just "url" for any method) => a
  # Response, or an exception to raise. Records every request it was asked for.
  class FakeTransport
    attr_reader :requests

    def initialize(routes)
      @routes = routes
      @requests = []
    end

    def request(method, uri, address:)
      @requests << [ method, uri.to_s, address ]
      answer = @routes.fetch("#{method.upcase} #{uri}") { @routes.fetch(uri.to_s) { Response.new(status: 404, location: nil) } }
      answer.is_a?(Exception) ? raise(answer) : answer
    end
  end

  class FakeResolver
    def initialize(hosts = {})
      @hosts = hosts
    end

    def addresses(host)
      @hosts.fetch(host, [ "93.184.215.14" ])
    end
  end

  def ok = Response.new(status: 200, location: nil)
  def status(code) = Response.new(status: code, location: nil)
  def redirect(to, code: 301) = Response.new(status: code, location: to)

  def check(url, routes = {}, hosts = {})
    @transport = FakeTransport.new(routes)
    LinkChecker.new(transport: @transport, resolver: FakeResolver.new(hosts)).check(url)
  end

  test "a page that answers 200 is ok, with a single HEAD request" do
    result = check("https://docs.example/guide", "https://docs.example/guide" => ok)

    assert_equal :ok, result.status
    assert_equal 200, result.http_status
    assert_equal [ [ :head, "https://docs.example/guide", "93.184.215.14" ] ], @transport.requests
  end

  test "a 404 is broken after trying GET as well" do
    result = check("https://docs.example/gone")

    assert_equal :broken, result.status
    assert_equal 404, result.http_status
    assert_equal %i[head get], @transport.requests.map(&:first)
  end

  test "410 and other 4xx answers are broken" do
    assert_equal :broken, check("https://a.example/", "https://a.example/" => status(410)).status
    assert_equal :broken, check("https://a.example/", "https://a.example/" => status(400)).status
  end

  test "falls back to GET when HEAD isn't allowed" do
    result = check("https://a.example/", "HEAD https://a.example/" => status(405), "GET https://a.example/" => ok)

    assert_equal :ok, result.status
    assert_equal %i[head get], @transport.requests.map(&:first)
  end

  test "sites that turn bots away are unverified, not broken" do
    [ 401, 403, 429, 999 ].each do |code|
      assert_equal :unverified, check("https://www.linkedin.com/learning", "https://www.linkedin.com/learning" => status(code)).status, "HTTP #{code}"
    end
  end

  test "server errors and timeouts are unverified, so a bad minute doesn't replace a link" do
    assert_equal :unverified, check("https://a.example/", "https://a.example/" => status(503)).status

    result = check("https://slow.example/", "https://slow.example/" => LinkChecker::Timeout.new("timed out"))
    assert_equal :unverified, result.status
    assert_equal "timed out", result.reason
  end

  test "a refused connection or TLS failure is broken" do
    result = check("https://down.example/", "https://down.example/" => LinkChecker::ConnectionFailed.new("connection failed"))

    assert_equal :broken, result.status
  end

  test "follows redirects, including relative ones, and reports where it ended" do
    routes = {
      "http://rubyonrails.org/docs" => redirect("https://rubyonrails.org/docs"),
      "https://rubyonrails.org/docs" => redirect("/docs/", code: 302),
      "https://rubyonrails.org/docs/" => ok
    }
    result = check("http://rubyonrails.org/docs", routes)

    assert_equal :ok, result.status
    assert_equal "https://rubyonrails.org/docs/", result.final_url
  end

  test "a redirect loop is broken" do
    routes = { "https://a.example/1" => redirect("https://a.example/2"), "https://a.example/2" => redirect("https://a.example/1") }

    result = check("https://a.example/1", routes)
    assert_equal :broken, result.status
    assert_equal "redirect loop", result.reason
  end

  test "more than three redirects is broken" do
    routes = (1..4).to_h { |n| [ "https://a.example/#{n}", redirect("https://a.example/#{n + 1}") ] }
    routes["https://a.example/5"] = ok

    result = check("https://a.example/1", routes)
    assert_equal :broken, result.status
    assert_match "more than 3 redirects", result.reason
    assert_equal 4, @transport.requests.size
  end

  test "exactly three redirects is fine" do
    routes = (1..3).to_h { |n| [ "https://a.example/#{n}", redirect("https://a.example/#{n + 1}") ] }
    routes["https://a.example/4"] = ok

    assert_equal :ok, check("https://a.example/1", routes).status
  end

  test "never connects to private, loopback, link-local or metadata addresses" do
    {
      "http://localhost/admin" => { "localhost" => [ "127.0.0.1" ] },
      "http://127.0.0.1/" => { "127.0.0.1" => [ "127.0.0.1" ] },
      "http://169.254.169.254/latest/meta-data/" => { "169.254.169.254" => [ "169.254.169.254" ] },
      "http://intranet.example/" => { "intranet.example" => [ "10.0.0.7" ] },
      "http://router.example/" => { "router.example" => [ "192.168.1.1" ] },
      "http://v6.example/" => { "v6.example" => [ "::1" ] },
      "http://mapped.example/" => { "mapped.example" => [ "::ffff:10.0.0.1" ] },
      "http://mixed.example/" => { "mixed.example" => [ "93.184.215.14", "172.16.0.5" ] }
    }.each do |url, hosts|
      result = check(url, {}, hosts)

      assert_equal :broken, result.status, url
      assert_equal "points at a private or internal address", result.reason, url
      assert_empty @transport.requests, "#{url} must not be requested"
    end
  end

  test "checks every redirect hop, so a public page can't bounce to an internal one" do
    routes = { "https://public.example/" => redirect("http://metadata.example/latest") }
    result = check("https://public.example/", routes, "metadata.example" => [ "169.254.169.254" ])

    assert_equal :broken, result.status
    assert_equal [ "https://public.example/" ], @transport.requests.map(&:second)
  end

  test "an unknown host is broken" do
    result = check("https://no-such-host.example/", {}, "no-such-host.example" => [])

    assert_equal :broken, result.status
    assert_equal "host not found", result.reason
  end

  test "only plain http(s) links on the usual ports are checked" do
    [ "ftp://files.example/a", "javascript:alert(1)", "file:///etc/passwd", "https://a.example:8080/", "https://user:pw@a.example/", "not a url", "" ].each do |url|
      result = check(url)

      assert_equal :broken, result.status, url
      assert_empty @transport.requests, url
    end
  end

  test "a redirect to a non-http(s) address is broken" do
    result = check("https://a.example/", "https://a.example/" => redirect("ftp://files.example/"))

    assert_equal :broken, result.status
    assert_equal 301, result.http_status
  end

  test "the fake checker reports listed links and remembers what it checked" do
    fake = LinkChecker::Fake.new(broken: [ "https://gone.example/" ], unverified: [ "https://medium.example/" ])

    assert fake.check("https://gone.example/").broken?
    assert_equal :unverified, fake.check("https://medium.example/").status
    assert fake.check("https://fine.example/").ok?
    assert_equal 3, fake.checked.size
  end

  test "tests use the fake checker by default" do
    assert_instance_of LinkChecker::Fake, LinkChecker.default
  end
end
