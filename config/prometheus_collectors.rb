# frozen_string_literal: true

require "prometheus_exporter/server"

class PwpushPrometheusCollector < PrometheusExporter::Server::TypeCollector
  DEFINITIONS = {
    "pushes_created" => ["pwpush_pushes_created_total", "Total pushes successfully created."],
    "retrievals" => ["pwpush_retrievals_total", "Total push retrieval events."],
    "authentication_events" => ["pwpush_authentication_events_total", "Total authentication events."],
    "uploaded_files" => ["pwpush_uploaded_files_total", "Total files attached to pushes."],
    "uploaded_file_bytes" => ["pwpush_uploaded_file_bytes_total", "Total bytes attached to file pushes."]
  }.freeze

  def initialize
    @metrics = DEFINITIONS.transform_values do |name, help|
      PrometheusExporter::Metric::Counter.new(name, help)
    end
  end

  def type
    "pwpush"
  end

  def collect(payload)
    metric = @metrics.fetch(payload.fetch("metric"))
    value = Float(payload.fetch("value", 1))
    labels = payload.fetch("labels", {}).transform_keys(&:to_sym)
    metric.observe(value, labels)
  end

  def metrics
    @metrics.values
  end
end
