# frozen_string_literal: true

require "test_helper"

class PrometheusAuthenticationTest < ActionDispatch::IntegrationTest
  class FakeClient
    attr_reader :payloads

    def initialize
      @payloads = []
    end

    def send_json(payload)
      payloads << payload
    end
  end

  setup do
    Settings.prometheus.enabled = true
    @client = FakeClient.new
    Pwpush::Metrics.client = @client
  end

  teardown do
    Settings.reload!
    Pwpush::Metrics.reset!
  end

  test "records successful login and logout without identity labels" do
    post user_session_path, params: {
      user: {email: users(:one).email, password: "password12345"}
    }
    delete destroy_user_session_path

    assert_metric(event: "login_success", mfa: "false")
    assert_metric(event: "logout", mfa: "false")
  end

  test "records failed login without identity labels" do
    post user_session_path, params: {
      user: {email: users(:one).email, password: "incorrect"}
    }

    assert_metric(event: "login_failure", mfa: "false")
  end

  test "does not report authentication guards as failed logins" do
    get pushes_path

    assert_empty @client.payloads
  end

  private

  def assert_metric(labels)
    assert_includes @client.payloads, {
      type: "pwpush",
      metric: :authentication_events,
      value: 1,
      labels: labels
    }
  end
end
