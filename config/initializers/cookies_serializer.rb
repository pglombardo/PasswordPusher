# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Specify a serializer for the signed and encrypted cookie jars.
# Valid options are :json, :marshal, and :hybrid.
#
# Marshal has a potential RCE vulnerability.
# If we switch directly to :json, app can 500 on cookie deserialization for old cookies
# Use :hybrid for now and aim for :json eventually.
# https://github.com/presidentbeef/brakeman/issues/1316
Rails.application.config.action_dispatch.cookies_serializer = :hybrid
