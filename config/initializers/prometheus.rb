# frozen_string_literal: true

# Prometheus metrics exporter configuration
# Documentation: https://github.com/discourse/prometheus_exporter

unless Rails.env.test?
  require "prometheus_exporter/middleware"
  require "prometheus_exporter/instrumentation"

  # Start the prometheus exporter process
  # This process will collect metrics and serve them on /metrics endpoint
  PrometheusExporter::Metric::Base.default_prefix = "pwpush"

  # Configure the client to send metrics to the exporter process
  PrometheusExporter::Client.default = PrometheusExporter::Client.new(
    host: ENV.fetch("PROMETHEUS_EXPORTER_HOST", "localhost"),
    port: ENV.fetch("PROMETHEUS_EXPORTER_PORT", 9394).to_i
  )

  # Use the middleware to track web requests
  Rails.application.middleware.unshift PrometheusExporter::Middleware

  # Puma metrics (if using Puma)
  if defined?(Puma)
    PrometheusExporter::Instrumentation::Puma.start
  end

  # Process metrics (CPU, memory, etc.)
  PrometheusExporter::Instrumentation::Process.start(type: "web")

  # ActiveRecord metrics (if using ActiveRecord)
  if defined?(ActiveRecord)
    PrometheusExporter::Instrumentation::ActiveRecord.start(
      custom_labels: {app: "password_pusher"},
      config_labels: [:database, :host]
    )
  end

  # Delayed Job metrics (if using Delayed Job)
  if defined?(Delayed::Job)
    PrometheusExporter::Instrumentation::DelayedJob.start
  end

  # Custom metrics collector for Password Pusher specific metrics
  # This will be used to track pushes, views, etc.
  class PasswordPusherMetricsCollector < PrometheusExporter::Server::TypeCollector
    def initialize
      @pushes_created = PrometheusExporter::Metric::Counter.new(
        "pushes_created_total",
        "Total number of pushes created"
      )
      @pushes_viewed = PrometheusExporter::Metric::Counter.new(
        "pushes_viewed_total",
        "Total number of pushes viewed"
      )
      @pushes_expired = PrometheusExporter::Metric::Counter.new(
        "pushes_expired_total",
        "Total number of pushes that have expired"
      )
    end

    def type
      "password_pusher"
    end

    def collect(obj)
      labels = obj["labels"] || {}

      case obj["action"]
      when "push_created"
        @pushes_created.observe(1, labels)
      when "push_viewed"
        @pushes_viewed.observe(1, labels)
      when "push_expired"
        @pushes_expired.observe(1, labels)
      end
    end

    def metrics
      [@pushes_created, @pushes_viewed, @pushes_expired]
    end
  end
end
