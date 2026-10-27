# frozen_string_literal: true

require_relative "trusted_proxies"

module PasswordPusher
  # Only proxy peers may provide forwarded request metadata. Without this
  # guard, ActionDispatch::RemoteIp assumes a proxy exists and a direct client
  # can choose a value from X-Forwarded-For.
  class TrustedProxyHeaders
    FORWARDED_HEADERS = %w[
      HTTP_X_FORWARDED_FOR
      HTTP_X_FORWARDED_HOST
      HTTP_X_FORWARDED_PORT
      HTTP_X_FORWARDED_PROTO
      HTTP_FORWARDED
      HTTP_CLIENT_IP
    ].freeze

    def initialize(app, trusted_proxies: nil)
      @app = app
      @trusted_proxies = trusted_proxies
    end

    def call(env)
      unless TrustedProxies.trusted?(env["REMOTE_ADDR"], trusted_proxies)
        FORWARDED_HEADERS.each { |header| env.delete(header) }
      end

      @app.call(env)
    end

    private

    def trusted_proxies
      @trusted_proxies || Rails.application.config.action_dispatch.trusted_proxies || TrustedProxies::DEFAULTS
    end
  end
end
