# frozen_string_literal: true

max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

rails_env = ENV.fetch("RAILS_ENV", "development")
environment rails_env

worker_count = 0
case rails_env
when "production"
  worker_count = Integer(ENV.fetch("WEB_CONCURRENCY") { 0 })
  workers worker_count

  preload_app!
when "development"
  worker_timeout 3600
end

port ENV.fetch("PORT", 5100)

# To restart: `bin/pwpush restart`
plugin :tmp_restart

start_web_prometheus_instrumentation = proc do
  next unless defined?(Pwpush::Metrics) && Pwpush::Metrics.enabled?

  require "prometheus_exporter/instrumentation"
  PrometheusExporter::Instrumentation::Process.start(type: "web")
  PrometheusExporter::Instrumentation::ActiveRecord.start(custom_labels: {type: "web"})
end

start_puma_prometheus_instrumentation = proc do
  next unless defined?(Pwpush::Metrics) && Pwpush::Metrics.enabled?

  require "prometheus_exporter/instrumentation"
  PrometheusExporter::Instrumentation::Puma.start unless PrometheusExporter::Instrumentation::Puma.started?
end

if worker_count.positive?
  before_worker_boot(&start_web_prometheus_instrumentation)
  after_worker_boot(&start_puma_prometheus_instrumentation)
else
  after_booted do
    start_web_prometheus_instrumentation.call
    start_puma_prometheus_instrumentation.call
  end
end
