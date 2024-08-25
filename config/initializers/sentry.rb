# frozen_string_literal: true

if ENV.key?("PWPUSH_COM") && defined?(Sentry)
  Sentry.init do |config|
    config.breadcrumbs_logger = [:active_support_logger]
    config.dsn = ENV["SENTRY_DSN"]
    config.enable_tracing = true
    config.traces_sample_rate = ENV["SENTRY_TRACES_SAMPLE_RATE"] || 0.1
    config.profiles_sample_rate = ENV["SENTRY_PROFILES_SAMPLE_RATE"] || 0.1
  end
end
