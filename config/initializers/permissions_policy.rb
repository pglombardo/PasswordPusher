# frozen_string_literal: true

# Be sure to restart your server when you modify this file.
#
# Password Pusher is a form-based app: copy-to-clipboard is the main browser
# capability we rely on. Everything else is denied by default.
#
# Rails emits Feature-Policy (legacy). Scanners expect Permissions-Policy
# (modern syntax), so both are configured here.

Rails.application.configure do
  config.permissions_policy do |policy|
    policy.accelerometer      :none
    policy.ambient_light_sensor :none
    policy.autoplay           :none
    policy.camera             :none
    policy.display_capture    :none
    policy.encrypted_media    :none
    policy.fullscreen         :none
    policy.geolocation        :none
    policy.gyroscope          :none
    policy.hid                :none
    policy.idle_detection     :none
    policy.magnetometer       :none
    policy.microphone         :none
    policy.midi               :none
    policy.payment            :none
    policy.picture_in_picture :none
    policy.screen_wake_lock   :none
    policy.serial             :none
    policy.sync_xhr           :none
    policy.usb                :none
    policy.web_share          :none
  end

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
    "web-share=()",
    "xr-spatial-tracking=()"
  ].join(", ")
end
