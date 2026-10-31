require "resolv"

class LinkChecker
  # Turns a host name into IP addresses (as strings). An IP literal comes back
  # as itself, so "http://127.0.0.1/" is still checked against the IP policy.
  class Resolver
    def initialize(timeout: 5)
      dns = Resolv::DNS.new
      dns.timeouts = timeout
      @resolv = Resolv.new([ Resolv::Hosts.new, dns ])
    end

    def addresses(host)
      host = host.to_s.delete_prefix("[").delete_suffix("]")
      return [ host ] if host.match?(Resolv::IPv4::Regex) || host.match?(Resolv::IPv6::Regex)

      @resolv.getaddresses(host).map(&:to_s).uniq
    rescue Resolv::ResolvError, Resolv::ResolvTimeout
      []
    end
  end
end
