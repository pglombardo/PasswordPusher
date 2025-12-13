# frozen_string_literal: true

# Track Devise authentication events in Prometheus
unless Rails.env.test?
  require_relative "../../app/models/concerns/prometheus_metrics"

  # Track successful logins
  Warden::Manager.after_authentication do |user, auth, opts|
    PrometheusMetrics.track_metric("user_login_success", {
      user_type: user.admin? ? "admin" : "user"
    })
  end

  # Track failed login attempts
  Warden::Manager.before_failure do |env, opts|
    PrometheusMetrics.track_metric("user_login_failed", {
      reason: opts[:message] || "invalid_credentials"
    })
  end

  # Track logout events
  Warden::Manager.before_logout do |user, auth, opts|
    PrometheusMetrics.track_metric("user_logout", {
      user_type: user.admin? ? "admin" : "user"
    })
  end
end
