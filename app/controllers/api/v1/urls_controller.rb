# frozen_string_literal: true

require "securerandom"

class Api::V1::UrlsController < Api::BaseController
  before_action :set_push, only: %i[show preview audit destroy]

  resource_description do
    name "URL Pushes"
    short "Interact directly with URL pushes.  This feature (and corresponding API) is currently in beta."
  end

  api :GET, "/r/:url_token.json", "Retrieve a URL push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["json"]
  description <<-EOS
    == URL Push Retrieval

    Retrieves a push including it's payload and details.  If the push is still active,
    this will burn a view and the transaction will be logged in the push audit log.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/r/fk27vnslkd.json

    == Example Response

      {
        "expire_after_days": 2,
        "expire_after_views": 5,
        "expired": false,
        "url_token": "quyul5r5w18",
        "payload": "https://example.com",
        ...
      }
  EOS
  def show
  end

  api :POST, "/r.json", "Create a new URL push."
  param :url, Hash, "Push details", required: true do
    param :payload, String, desc: "The URL encoded URL to redirect to.", required: true
    param :passphrase, String, desc: "Require recipients to enter this passphrase to view the created push."
    param :name, String, desc: "Visible only to the push creator.", allow_blank: true
    param :note, String,
      desc: "If authenticated, the URL encoded note for this push.  Visible only to the push creator.", allow_blank: true
    param :expire_after_days, Integer, desc: "Expire secret link and delete after this many days."
    param :expire_after_views, Integer, desc: "Expire secret link and delete after this many views."
    param :retrieval_step, %w[true false], desc: "Helps to avoid chat systems and URL scanners from eating up views."
  end
  formats ["json"]
  description <<-EOS
    == URL Push Creation

    Creates a new URL push with the given payload and details.

    == Example Request

    curl -X POST \\
      -H "Authorization: Bearer MyAPIToken" \\
      -d "url[payload]=https://example.com" \\
      -d "url[expire_after_days]=2" \\
      -d "url[expire_after_views]=10" \\
      https://pwpush.com/r.json

    == Example Response

      {
        "url_token": "quyul5r5w18",
        "created_at": "2023-10-20T15:32:01Z",
        "expire_after_days": 2,
        "expire_after_views": 10,
        ...
      }
  EOS
  def create
  end

  api :GET, "/r/:url_token/preview.json", "Helper endpoint to retrieve the fully qualified secret URL of a push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["json"]
  description <<-EOS
    == URL Push Preview

    Retrieves the fully qualified secret URL of a push.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/r/fk27vnslkd/preview.json

    == Example Response

      {
        "url": "https://pwpush.com/r/fk27vnslkd"
      }
  EOS
  def preview
  end

  api :GET, "/r/:url_token/audit.json", "Retrieve the audit log for a push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["json"]
  description <<-EOS
    == URL Push Audit

    Retrieves the audit log for a push.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/r/fk27vnslkd/audit.json

    == Example Response

      [
        {
          "ip": "127.0.0.1",
          "referrer": "https://example.com",
          "created_at": "2023-10-20T15:32:01Z",
          "successful": true,
          ...
        },
        ...
      ]
  EOS
  def audit
  end

  api :DELETE, "/r/:url_token.json", "Expire a push: delete the payload and expire the secret URL."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["json"]
  description <<-EOS
    == URL Push Expiration

    Expires a push immediately.  Must be authenticated & owner of the push _or_ the push must
    have been created with _deleteable_by_viewer_.

    == Example Request

      curl -X DELETE \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/r/fkwjfvhall92.json

    == Example Response

      {
        "expired": true,
        "expired_on": "2023-10-23T15:32:01Z",
        ...
      }
  EOS
  def destroy
  end

  api :GET, "/r/active.json", "Retrieve your active URL pushes."
  formats ["json"]
  description <<-EOS
    == Active URL Pushes Retrieval

    Returns the list of URL pushes that you previously pushed which are still active.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/r/active.json

    == Example Response

      [
        {
          "url_token": "fkwjfvhall92",
          "name": null,
          "created_at": "2023-10-20T15:32:01Z",
          "expires_on": "2023-10-23T15:32:01Z",
          ...
        },
        ...
      ]
  EOS
  def active
  end

  api :GET, "/r/expired.json", "Retrieve your expired URL pushes."
  formats ["json"]
  description <<-EOS
    == Expired URL Pushes Retrieval

    Returns the list of URL pushes that you previously pushed which have expired.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/r/expired.json

    == Example Response

      [
        {
          "url_token": "fkwjfvhall92",
          "created_at": "2023-10-20T15:32:01Z",
          "expires_on": "2023-10-23T15:32:01Z",
          ...
        },
        ...
      ]
  EOS
  def expired
  end
end
