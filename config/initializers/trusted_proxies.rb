# frozen_string_literal: true

require "password_pusher/trusted_proxies"

# Custom trusted proxies from Settings (PWP__TRUSTED_PROXIES or settings.yml).
# Appended as IPAddr objects so a CIDR range matches hosts inside it.
# The default private ranges are set in the environment files.
if Settings.trusted_proxies.present?
  parsed = PasswordPusher::TrustedProxies.parse(Settings.trusted_proxies)
  dispatch = Rails.application.config.action_dispatch
  if dispatch.trusted_proxies.nil?
    dispatch.trusted_proxies = parsed
  else
    dispatch.trusted_proxies.concat(parsed)
  end
end
