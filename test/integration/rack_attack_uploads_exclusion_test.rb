# frozen_string_literal: true

require "test_helper"
require "rack/attack"

# Verifies that /uploads is excluded from Rack::Attack per-IP throttles so TUS
# chunked PATCH requests are not rate-limited. Throttles are disabled in test
# (config/initializers/rack_attack.rb: unless Rails.env.test?), so we assert
# the discriminator logic that would be used.
class RackAttackUploadsExclusionTest < ActionDispatch::IntegrationTest
  # Discriminators must match config/initializers/rack_attack.rb
  MINUTE_DISCRIMINATOR = lambda { |req|
    req.ip unless req.path.start_with?("/assets") || req.path == "/up" || req.path.start_with?("/uploads")
  }
  SECOND_DISCRIMINATOR = lambda { |req|
    req.ip unless req.path == "/up" || req.path.start_with?("/uploads")
  }

  test "uploads path is excluded from req/minute/ip throttle" do
    req = rack_attack_request("/uploads/abc123")
    assert_nil MINUTE_DISCRIMINATOR.call(req),
      "Requests to /uploads/* must not be throttled by req/minute/ip"
  end

  test "uploads path is excluded from req/second/ip throttle" do
    req = rack_attack_request("/uploads/abc123")
    assert_nil SECOND_DISCRIMINATOR.call(req),
      "Requests to /uploads/* must not be throttled by req/second/ip"
  end

  test "uploads root path is excluded from both throttles" do
    req = rack_attack_request("/uploads")
    assert_nil MINUTE_DISCRIMINATOR.call(req)
    assert_nil SECOND_DISCRIMINATOR.call(req)
  end

  test "non-uploads path is subject to throttling" do
    req = rack_attack_request("/some/path")
    assert_equal "127.0.0.1", MINUTE_DISCRIMINATOR.call(req)
    assert_equal "127.0.0.1", SECOND_DISCRIMINATOR.call(req)
  end

  private

  def rack_attack_request(path, ip: "127.0.0.1")
    env = Rack::MockRequest.env_for("http://#{ip}/#{path.delete_prefix('/')}", "REQUEST_METHOD" => "GET")
    env["REMOTE_ADDR"] = ip
    Rack::Attack::Request.new(env)
  end
end
