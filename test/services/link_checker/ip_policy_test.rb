require "test_helper"

class LinkChecker::IpPolicyTest < ActiveSupport::TestCase
  test "blocks internal and reserved addresses" do
    %w[
      127.0.0.1 127.1.2.3 10.1.2.3 172.16.0.1 172.31.255.255 192.168.0.10 169.254.169.254
      100.64.0.1 0.0.0.0 224.0.0.1 255.255.255.255 198.18.0.1
      ::1 :: fe80::1 fc00::1 fd00:ec2::254 ff02::1 ::ffff:127.0.0.1 ::ffff:192.168.1.1 64:ff9b::a00:1
    ].each { |address| assert LinkChecker::IpPolicy.blocked?(address), address }
  end

  test "allows public addresses" do
    %w[93.184.215.14 8.8.8.8 172.32.0.1 151.101.1.140 2606:4700::6810:84e5 ::ffff:8.8.8.8].each do |address|
      assert_not LinkChecker::IpPolicy.blocked?(address), address
    end
  end

  test "treats anything that isn't an IP address as blocked" do
    assert LinkChecker::IpPolicy.blocked?("example.com")
    assert LinkChecker::IpPolicy.blocked?("")
  end
end
