require "ipaddr"

class LinkChecker
  # Addresses a link check must never connect to: our own machine, private
  # networks, link-local (which includes the 169.254.169.254 cloud metadata
  # service), carrier-grade NAT, multicast and other reserved ranges.
  module IpPolicy
    BLOCKED_RANGES = %w[
      0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12
      192.0.0.0/24 192.0.2.0/24 192.168.0.0/16 198.18.0.0/15 198.51.100.0/24
      203.0.113.0/24 224.0.0.0/4 240.0.0.0/4
      ::/128 ::1/128 64:ff9b::/96 100::/64 2001:db8::/32 fc00::/7 fe80::/10 ff00::/8
    ].map { |range| IPAddr.new(range) }.freeze

    def self.blocked?(address)
      ip = IPAddr.new(address.to_s)
      # ::ffff:10.0.0.1 is 10.0.0.1 in disguise.
      ip = ip.native if ip.ipv4_mapped? || ip.ipv4_compat?
      BLOCKED_RANGES.any? { |range| range.family == ip.family && range.include?(ip) }
    rescue IPAddr::InvalidAddressError
      true
    end
  end
end
