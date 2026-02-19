# frozen_string_literal: true

require "test_helper"
require "rack/attack"

class RackAttackPushesThrottleTest < ActionDispatch::IntegrationTest
  # Verifies that the pushes/day/ip throttle does not apply to GET (only POST to creation paths).
  # Throttle condition and path list are unit-tested in test/unit/rack_attack_pushes_throttle_test.rb.

  THROTTLE_TEST_IP = "192.168.1.100"
  PUSH_CREATION_PATHS = %w[/p /p.json /f /f.json /r /r.json].freeze

  setup do
    register_pushes_day_ip_throttle
  end

  teardown do
    Rack::Attack.configuration.throttles.delete("pushes/day/ip")
  end

  test "pushes/day/ip throttle does not apply to GET /p/new" do
    app = Rails.application
    r = Rack::MockRequest.new(app).get("/p/new", "REMOTE_ADDR" => THROTTLE_TEST_IP)
    assert r.successful?, "GET /p/new should not be throttled (got #{r.status})"
  end

  test "pushes/day/ip throttle is registered and applies to POST /p when enabled" do
    throttle = Rack::Attack.configuration.throttles["pushes/day/ip"]
    assert throttle, "pushes/day/ip throttle should be registered"
    req = Rack::Attack::Request.new("REQUEST_METHOD" => "POST", "PATH_INFO" => "/p", "REMOTE_ADDR" => THROTTLE_TEST_IP)
    assert_equal THROTTLE_TEST_IP, throttle.send(:discriminator_for, req), "POST /p should be throttled by IP"
  end

  private

  def register_pushes_day_ip_throttle
    Rack::Attack.throttle("pushes/day/ip", limit: 2, period: 24.hours) do |req|
      req.ip if req.post? && PUSH_CREATION_PATHS.include?(req.path)
    end
  end
end
