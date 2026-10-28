# frozen_string_literal: true

require "test_helper"

class PasswordPusher::TrustedProxyHeadersTest < ActiveSupport::TestCase
  test "removes forwarded headers from an untrusted direct peer" do
    response = call(
      "REMOTE_ADDR" => "8.8.8.8",
      "HTTP_X_FORWARDED_FOR" => "1.2.3.4",
      "HTTP_FORWARDED" => "for=1.2.3.4",
      "HTTP_CLIENT_IP" => "1.2.3.4"
    )

    assert_nil response["HTTP_X_FORWARDED_FOR"]
    assert_nil response["HTTP_FORWARDED"]
    assert_nil response["HTTP_CLIENT_IP"]
  end

  test "preserves forwarded headers from a trusted proxy peer" do
    response = call(
      "REMOTE_ADDR" => "10.0.0.5",
      "HTTP_X_FORWARDED_FOR" => "1.2.3.4"
    )

    assert_equal "1.2.3.4", response["HTTP_X_FORWARDED_FOR"]
  end

  test "uses the socket peer IP when a direct client forges X-Forwarded-For" do
    assert_equal "8.8.8.8", remote_ip(
      "REMOTE_ADDR" => "8.8.8.8",
      "HTTP_X_FORWARDED_FOR" => "1.2.3.4, 192.168.1.1"
    )
  end

  test "uses X-Forwarded-For when the direct peer is trusted" do
    assert_equal "1.2.3.4", remote_ip(
      "REMOTE_ADDR" => "10.0.0.5",
      "HTTP_X_FORWARDED_FOR" => "1.2.3.4, 10.0.0.5"
    )
  end

  test "preserves forwarded headers from an IPv4-mapped trusted proxy" do
    response = call(
      "REMOTE_ADDR" => "::ffff:10.0.0.5",
      "HTTP_X_FORWARDED_FOR" => "1.2.3.4"
    )

    assert_equal "1.2.3.4", response["HTTP_X_FORWARDED_FOR"]
  end

  test "drops forwarded headers from an IPv4-mapped public client" do
    response = call(
      "REMOTE_ADDR" => "::ffff:8.8.8.8",
      "HTTP_X_FORWARDED_FOR" => "1.2.3.4"
    )

    assert_nil response["HTTP_X_FORWARDED_FOR"]
  end

  test "uses a configured trusted proxy CIDR" do
    headers = {
      "REMOTE_ADDR" => "203.0.113.10",
      "HTTP_X_FORWARDED_FOR" => "1.2.3.4"
    }

    assert_equal "1.2.3.4", call(headers, PasswordPusher::TrustedProxies.parse("203.0.113.0/24"))["HTTP_X_FORWARDED_FOR"]
  end

  private

  def call(env, trusted_proxies = PasswordPusher::TrustedProxies::DEFAULTS)
    app = PasswordPusher::TrustedProxyHeaders.new(
      ->(request_env) { [200, {}, [request_env]] },
      trusted_proxies:
    )
    app.call(env).last.first
  end

  def remote_ip(env)
    endpoint = ->(request_env) { [200, {}, [ActionDispatch::Request.new(request_env).remote_ip]] }
    remote_ip = ActionDispatch::RemoteIp.new(endpoint, true, PasswordPusher::TrustedProxies::DEFAULTS)
    app = PasswordPusher::TrustedProxyHeaders.new(remote_ip, trusted_proxies: PasswordPusher::TrustedProxies::DEFAULTS)

    app.call(env).last.first
  end
end
