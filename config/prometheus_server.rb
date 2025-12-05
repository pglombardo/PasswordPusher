#!/usr/bin/env ruby
# frozen_string_literal: true

# Prometheus Exporter Server
# This script starts the Prometheus metrics collection server
# Run this in a separate process alongside your Rails application
#
# Usage:
#   bundle exec ruby config/prometheus_server.rb

require "prometheus_exporter"
require "prometheus_exporter/server"
require "prometheus_exporter/instrumentation"

# Load the custom collector
require_relative "../app/models/concerns/prometheus_metrics"

# Custom collector for Password Pusher metrics
class PasswordPusherMetricsCollector < PrometheusExporter::Server::TypeCollector
  def initialize
    @pushes_created = PrometheusExporter::Metric::Counter.new(
      "pwpush_pushes_created_total",
      "Total number of pushes created"
    )
    @pushes_viewed = PrometheusExporter::Metric::Counter.new(
      "pwpush_pushes_viewed_total",
      "Total number of pushes viewed"
    )
    @pushes_expired = PrometheusExporter::Metric::Counter.new(
      "pwpush_pushes_expired_total",
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

# Configuration
port = ENV.fetch("PROMETHEUS_EXPORTER_PORT", 9394).to_i
host = ENV.fetch("PROMETHEUS_EXPORTER_HOST", "localhost")

puts "Starting Prometheus Exporter Server on #{host}:#{port}"
puts "Metrics will be available at http://#{host}:#{port}/metrics"

# Create and start the server
server = PrometheusExporter::Server::WebServer.new(port: port, bind: host)

# Register the custom collector
server.collector.register_collector(PasswordPusherMetricsCollector.new)

# Start the server
server.start

# Keep the process running
sleep
