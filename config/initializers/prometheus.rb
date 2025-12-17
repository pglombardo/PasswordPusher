# frozen_string_literal: true

# Prometheus metrics exporter configuration
# Documentation: https://github.com/discourse/prometheus_exporter

unless Rails.env.test?
  require "prometheus_exporter/middleware"
  require "prometheus_exporter/instrumentation"

  # Configure the client to send metrics to the exporter process
  PrometheusExporter::Client.default = PrometheusExporter::Client.new(
    host: ENV.fetch("PROMETHEUS_EXPORTER_HOST", "localhost"),
    port: ENV.fetch("PROMETHEUS_EXPORTER_PORT", 9394).to_i
  )

  # Use the middleware to track web requests
  Rails.application.middleware.unshift PrometheusExporter::Middleware

  # Puma metrics (only in production with clustered mode)
  # Disabled in development as single-mode Puma doesn't support stats
  if defined?(Puma) && File.basename($PROGRAM_NAME) != "rake" && Rails.env.production?
    Rails.application.config.after_initialize do
      PrometheusExporter::Instrumentation::Puma.start
    rescue StandardError => e
      Rails.logger.warn("Puma metrics not available: #{e.message}")
    end
  end

  # Process metrics (CPU, memory, etc.)
  # Use "web" type for web processes, "sidekiq" for workers
  process_type = File.basename($PROGRAM_NAME) == "rake" ? "sidekiq" : "web"
  PrometheusExporter::Instrumentation::Process.start(type: process_type)

  # ActiveRecord metrics (if using ActiveRecord)
  if defined?(ActiveRecord)
    PrometheusExporter::Instrumentation::ActiveRecord.start(
      custom_labels: {app: "password_pusher"},
      config_labels: [:database, :host]
    )
  end
end
