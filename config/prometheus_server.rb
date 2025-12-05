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
    # Push metrics
    @pushes_created = PrometheusExporter::Metric::Counter.new(
      "pwpush_pushes_created_total",
      "Total number of pushes created"
    )
    @pushes_viewed = PrometheusExporter::Metric::Counter.new(
      "pwpush_pushes_viewed_total",
      "Total number of pushes viewed successfully"
    )
    @pushes_expired = PrometheusExporter::Metric::Counter.new(
      "pwpush_pushes_expired_total",
      "Total number of pushes that have expired"
    )
    @pushes_failed_view = PrometheusExporter::Metric::Counter.new(
      "pwpush_pushes_failed_view_total",
      "Total number of failed view attempts (expired/deleted)"
    )
    @pushes_failed_passphrase = PrometheusExporter::Metric::Counter.new(
      "pwpush_pushes_failed_passphrase_total",
      "Total number of failed passphrase attempts"
    )

    # File upload metrics
    @file_uploads_total = PrometheusExporter::Metric::Counter.new(
      "pwpush_file_uploads_total",
      "Total number of files uploaded"
    )
    @file_upload_bytes = PrometheusExporter::Metric::Counter.new(
      "pwpush_file_upload_bytes_total",
      "Total bytes uploaded in files"
    )

    # User authentication metrics
    @user_signup = PrometheusExporter::Metric::Counter.new(
      "pwpush_user_signup_total",
      "Total number of user signups"
    )
    @user_login_success = PrometheusExporter::Metric::Counter.new(
      "pwpush_user_login_success_total",
      "Total number of successful logins"
    )
    @user_login_failed = PrometheusExporter::Metric::Counter.new(
      "pwpush_user_login_failed_total",
      "Total number of failed login attempts"
    )
    @user_logout = PrometheusExporter::Metric::Counter.new(
      "pwpush_user_logout_total",
      "Total number of user logouts"
    )
    @user_locked = PrometheusExporter::Metric::Counter.new(
      "pwpush_user_locked_total",
      "Total number of users locked due to failed login attempts"
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
      # Track file upload metrics if present
      if labels["file_count"]
        file_labels = {kind: labels["kind"], user_type: labels["user_type"]}
        @file_uploads_total.observe(labels["file_count"].to_i, file_labels)
        @file_upload_bytes.observe(labels["total_file_size"].to_i, file_labels)
      end
    when "push_viewed"
      @pushes_viewed.observe(1, labels)
    when "push_expired"
      @pushes_expired.observe(1, labels)
    when "push_failed_view"
      @pushes_failed_view.observe(1, labels)
    when "push_failed_passphrase"
      @pushes_failed_passphrase.observe(1, labels)
    when "user_signup"
      @user_signup.observe(1, labels)
    when "user_login_success"
      @user_login_success.observe(1, labels)
    when "user_login_failed"
      @user_login_failed.observe(1, labels)
    when "user_logout"
      @user_logout.observe(1, labels)
    when "user_locked"
      @user_locked.observe(1, labels)
    end
  end

  def metrics
    [
      @pushes_created,
      @pushes_viewed,
      @pushes_expired,
      @pushes_failed_view,
      @pushes_failed_passphrase,
      @file_uploads_total,
      @file_upload_bytes,
      @user_signup,
      @user_login_success,
      @user_login_failed,
      @user_logout,
      @user_locked
    ]
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
