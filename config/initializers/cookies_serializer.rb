# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Specify a serializer for the signed and encrypted cookie jars.
# Valid options are :json, :marshal, and :hybrid.
#
# Marshal has a potential RCE vulnerability.
# If we switch directly to :json, app can 500 on cookie deserialization for old cookies
# We were on :hybrid but have now moved to :json and rotated the secret key base
# https://github.com/presidentbeef/brakeman/issues/1316
Rails.application.config.action_dispatch.cookies_serializer = :json
