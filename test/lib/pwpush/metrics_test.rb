# frozen_string_literal: true

require "test_helper"
require Rails.root.join("config/prometheus_collectors")

class Pwpush::MetricsTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :payloads

    def initialize
      @payloads = []
    end

    def send_json(payload)
      payloads << payload
    end
  end

  class FailingClient
    def send_json(_payload)
      raise Errno::ECONNREFUSED
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

  test "sends exact metric payload with string label values" do
    Pwpush::Metrics.increment(
      :pushes_created,
      value: 2,
      labels: {kind: :text, authenticated: false}
    )

    assert_equal [{
      type: "pwpush",
      metric: :pushes_created,
      value: 2,
      labels: {kind: "text", authenticated: "false"}
    }], @client.payloads
  end

  test "does not send metrics when disabled" do
    Settings.prometheus.enabled = false

    Pwpush::Metrics.increment(:pushes_created)

    assert_empty @client.payloads
  end

  test "metric delivery failures do not affect application code" do
    Pwpush::Metrics.client = FailingClient.new

    assert_nil Pwpush::Metrics.increment(:pushes_created)
  end

  test "collector exports custom counters with bounded labels" do
    collector = PwpushPrometheusCollector.new
    collector.collect(
      "metric" => "retrievals",
      "value" => 1,
      "labels" => {"kind" => "text", "event" => "view"}
    )

    output = collector.metrics.map(&:to_prometheus_text).join("\n")
    assert_includes output, "pwpush_retrievals_total{kind=\"text\",event=\"view\"} 1"
  end

  test "audit events record creation, upload, and retrieval metrics" do
    push = Push.new(
      kind: "file",
      expire_after_days: 7,
      expire_after_views: 5
    )
    fixture = file_fixture("test-file.txt")
    push.files.attach(io: File.open(fixture), filename: fixture.basename.to_s)
    push.save!

    push.audit_logs.create!(kind: :creation)
    push.audit_logs.create!(kind: :view)

    assert_includes @client.payloads, {
      type: "pwpush",
      metric: :pushes_created,
      value: 1,
      labels: {kind: "file", authenticated: "false"}
    }
    assert_includes @client.payloads, {
      type: "pwpush",
      metric: :uploaded_files,
      value: 1,
      labels: {}
    }
    assert_includes @client.payloads, {
      type: "pwpush",
      metric: :uploaded_file_bytes,
      value: fixture.size,
      labels: {}
    }
    assert_includes @client.payloads, {
      type: "pwpush",
      metric: :retrievals,
      value: 1,
      labels: {kind: "file", event: "view"}
    }
  end
end
