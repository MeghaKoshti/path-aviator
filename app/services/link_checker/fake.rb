class LinkChecker
  # Offline stand-in used by tests: every link is fine unless listed.
  #
  #   LinkChecker::Fake.new(broken: [ "https://gone.example/" ], unverified: [ ... ])
  class Fake
    attr_reader :checked

    def initialize(broken: [], unverified: [])
      @broken = broken
      @unverified = unverified
      @checked = []
    end

    def check(url)
      @checked << url
      status = if @broken.include?(url) then :broken
      elsif @unverified.include?(url) then :unverified
      else :ok
      end
      Result.new(status:, http_status: { ok: 200, broken: 404, unverified: 403 }[status], final_url: url, reason: nil)
    end
  end
end
