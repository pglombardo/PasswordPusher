# frozen_string_literal: true

Apipie.configure do |config|
  config.app_name = "Password Pusher"
  config.copyright = "&copy; 2011-Present Peter Giacomo Lombardo"
  config.api_base_url = ""
  config.api_base_url["1.5"] = ""
  config.doc_base_url = "/api"
  config.api_controllers_matcher = Rails.root.join("app/controllers/**/*.rb").to_s
  config.validate = false
  config.default_version = "1.5"
  config.app_info = <<-APPINFO
    The Password Pusher JSON API.

    This API allows for both anonymous and authenticated access.

    For more information including language-specific examples to copy, see: https://docs.pwpush.com/docs/json-api/

    == Authentication

    To authenticate, get your API token from {the API token page}[/api_tokens] and then apply it in your
    API calls as request headers:

        'Authorization': "Bearer <token>"

    == Examples

    Curl

        curl -X POST -H "Authorization: Bearer YOUR_API_TOKEN" --data "password[payload]=mypassword" https://pwpush.com/p.json

    For more information including language-specific examples to copy, see: https://docs.pwpush.com/docs/json-api/

    == February 2025 Update (v1.4)

    Added a new version endpoint to get the current application version, API version, and edition information.  This will be expanded
    soon to include more information.

    == February 2025 Update (v1.3)

    The API has been updated to use Bearer tokens for authentication and a general cleanup of the API.

    The X-User-Email and X-User-Token headers are deprecated although they will probably still be supported indefinitely for v1 of the API (and not carried into the eventual APIv2).

    Some clients may need minor updates if they were relying on non-standard behavior.

    If something has broken recently, please see this {pull request}[https://github.com/pglombardo/PasswordPusher/pull/3068] for more details.

    == May 2024 Update

    /f and /r paths are now merged into /p.  Please use /p/* & /p.json for all new API calls.
  APPINFO
end
