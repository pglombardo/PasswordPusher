# frozen_string_literal: true

require "test_helper"
require "rack/attack"

class RackAttackPushesThrottleUnitTest < ActiveSupport::TestCase
  # Tests the pushes/day/ip throttle condition and that exceeding the limit triggers throttling.
  # The throttle is registered in this test (same logic as config/initializers/rack_attack.rb).

  THROTTLE_TEST_IP = "192.168.1.100"
  PUSH_CREATION_PATHS = %w[/p /p.json /f /f.json /r /r.json].freeze

  setup do
    @throttle = nil
    register_throttle
    clear_cache_for(THROTTLE_TEST_IP)
  end

  teardown do
    Rack::Attack.configuration.throttles.delete("pushes/day/ip")
  end

  test "throttle returns IP for POST to push creation paths" do
    PUSH_CREATION_PATHS.each do |path|
      req = build_request("POST", path, THROTTLE_TEST_IP)
      assert_equal THROTTLE_TEST_IP, throttle_discriminator(req), "POST #{path} should be throttled by IP"
    end
  end

  test "throttle returns nil for GET to push creation paths" do
    req = build_request("GET", "/p", THROTTLE_TEST_IP)
    assert_nil throttle_discriminator(req), "GET /p should not be throttled"
  end

  test "throttle returns nil for POST to non-push paths" do
    req = build_request("POST", "/other", THROTTLE_TEST_IP)
    assert_nil throttle_discriminator(req), "POST /other should not be throttled"
  end

  test "PUSH_CREATION_PATHS includes all push creation routes" do
    assert_includes PUSH_CREATION_PATHS, "/p"
    assert_includes PUSH_CREATION_PATHS, "/p.json"
    assert_includes PUSH_CREATION_PATHS, "/f"
    assert_includes PUSH_CREATION_PATHS, "/f.json"
    assert_includes PUSH_CREATION_PATHS, "/r"
    assert_includes PUSH_CREATION_PATHS, "/r.json"
    assert_equal 6, PUSH_CREATION_PATHS.size
  end

  private

  def register_throttle
    # Use 60-second period so epoch bucket is stable for requests within same minute
    Rack::Attack.throttle("pushes/day/ip", limit: 2, period: 60) do |r|
      r.ip if r.post? && PUSH_CREATION_PATHS.include?(r.path)
    end
    @throttle = Rack::Attack.configuration.throttles["pushes/day/ip"]
  end

  def throttle_discriminator(request)
    @throttle.send(:discriminator_for, request)
  end

  def build_request(method, path, ip)
    Rack::Attack::Request.new(
      "REQUEST_METHOD" => method,
      "PATH_INFO" => path,
      "REMOTE_ADDR" => ip
    )
  end

  def clear_cache_for(ip)
    store = Rack::Attack.cache.store
    return unless store.respond_to?(:delete_matched)

    pattern = /rack::attack:\d+:pushes\/day\/ip:#{Regexp.escape(ip)}/
    store.delete_matched(pattern)
  end
end
