# frozen_string_literal: true

require "test_helper"

class PasswordPusher::TrustedProxiesTest < ActiveSupport::TestCase
  test "parses a single address and a CIDR into IPAddr objects" do
    proxies = PasswordPusher::TrustedProxies.parse("203.0.113.10, 198.51.100.0/24")

    assert_equal 2, proxies.size
    assert_instance_of IPAddr, proxies[0]
    assert_instance_of IPAddr, proxies[1]
    assert proxies[0] === "203.0.113.10"
    assert proxies[1] === "198.51.100.8"
    refute proxies[1] === "198.51.101.8"
  end

  test "parses a settings.yml list" do
    proxies = PasswordPusher::TrustedProxies.parse(["203.0.113.10", "2001:db8::/32"])

    assert proxies[0] === "203.0.113.10"
    assert proxies[1] === "2001:db8::1"
    refute proxies[1] === "2001:db9::1"
  end

  test "skips blank and invalid entries" do
    proxies = PasswordPusher::TrustedProxies.parse(" , not-an-ip, 203.0.113.0/24 ")

    assert_equal 1, proxies.size
    assert proxies.first === "203.0.113.10"
  end

  test "returns an empty list for a blank value" do
    assert_empty PasswordPusher::TrustedProxies.parse(nil)
    assert_empty PasswordPusher::TrustedProxies.parse("")
    assert_empty PasswordPusher::TrustedProxies.parse([])
  end

  test "a parsed CIDR is skipped when that proxy appears in X-Forwarded-For" do
    proxies = PasswordPusher::TrustedProxies.parse("203.0.113.0/24")
    request = ActionDispatch::Request.new(
      "REMOTE_ADDR" => "203.0.113.10",
      "HTTP_X_FORWARDED_FOR" => "198.51.100.20, 203.0.113.10"
    )

    ip = ActionDispatch::RemoteIp::GetIp.new(request, true, proxies).calculate_ip

    assert_equal "198.51.100.20", ip
  end

  test "a parsed single address is trusted the same way" do
    proxies = PasswordPusher::TrustedProxies.parse("203.0.113.10")
    request = ActionDispatch::Request.new(
      "REMOTE_ADDR" => "203.0.113.10",
      "HTTP_X_FORWARDED_FOR" => "198.51.100.20, 203.0.113.10"
    )

    ip = ActionDispatch::RemoteIp::GetIp.new(request, true, proxies).calculate_ip

    assert_equal "198.51.100.20", ip
  end

  test "a CIDR left as a string is selected as the client IP" do
    request = ActionDispatch::Request.new(
      "REMOTE_ADDR" => "203.0.113.10",
      "HTTP_X_FORWARDED_FOR" => "198.51.100.20, 203.0.113.10"
    )

    ip = ActionDispatch::RemoteIp::GetIp.new(request, true, ["203.0.113.0/24"]).calculate_ip

    assert_equal "203.0.113.10", ip
  end
end
