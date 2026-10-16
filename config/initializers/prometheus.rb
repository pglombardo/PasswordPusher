# frozen_string_literal: true

require Rails.root.join("lib/pwpush/metrics")

if Pwpush::Metrics.enabled?
  require "prometheus_exporter/instrumentation"
  require "prometheus_exporter/middleware"

  PrometheusExporter::Client.default = Pwpush::Metrics.client
  Rails.application.config.middleware.unshift PrometheusExporter::Middleware, instrument: :prepend

  if ENV["PWP_PROCESS_TYPE"] == "worker"
    PrometheusExporter::Instrumentation::Process.start(type: "solid_queue")
    PrometheusExporter::Instrumentation::ActiveRecord.start(custom_labels: {type: "solid_queue"})
  end
end
