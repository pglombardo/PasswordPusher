# frozen_string_literal: true

# Be sure to restart your server when you modify this file.
#
# Password Pusher is a form-based app: copy-to-clipboard is the main browser
# capability we rely on. Everything else is denied by default.
#
# Permissions-Policy is set directly. Rails' config.permissions_policy also
# emits the legacy Feature-Policy header. Browsers warn when both headers
# name the same features, and when either header includes retired names
# such as ambient-light-sensor or web-share.

Rails.application.configure do
  config.action_dispatch.default_headers["Permissions-Policy"] = [
    "accelerometer=()",
    "autoplay=()",
    "camera=()",
    "clipboard-write=(self)",
    "display-capture=()",
    "encrypted-media=()",
    "fullscreen=()",
    "geolocation=()",
    "gyroscope=()",
    "hid=()",
    "idle-detection=()",
    "magnetometer=()",
    "microphone=()",
    "midi=()",
    "payment=()",
    "picture-in-picture=()",
    "publickey-credentials-get=()",
    "screen-wake-lock=()",
    "serial=()",
    "sync-xhr=()",
    "usb=()",
    "xr-spatial-tracking=()"
  ].join(", ")
end
