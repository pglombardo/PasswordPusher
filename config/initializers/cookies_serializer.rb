# Be sure to restart your server when you modify this file.

# Specify a serializer for the signed and encrypted cookie jars.
# Valid options are :json, :marshal, and :hybrid.
# Marshal has a known RCE vulnerability. Use :json instead.
Rails.application.config.action_dispatch.cookies_serializer = :json
