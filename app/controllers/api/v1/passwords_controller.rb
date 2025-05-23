# frozen_string_literal: true

require "securerandom"

class Api::V1::PasswordsController < Api::BaseController
  before_action :set_push, only: %i[show preview audit destroy]

  resource_description do
    name "Text Pushes"
    short "Interact directly with text pushes."
  end

  api :GET, "/p/:url_token.json", "Retrieve a push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["JSON"]
  description <<-EOS
    == Retrieving a Push

    Retrieves a push and its payload. If the push is active, this request will count as a view and be logged in the audit log.

    === Security Features

    * Passphrase protection - Requires a passphrase to view.

      Provide the passphrase as a GET parameter: ?passphrase=xxx

    === Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/p/fk27vnslkd.json

    === Example Response

      {
        "payload": "secret_text",
        "passphrase": null,
        "note": "By user initiated request from the user@example.com account",
        "expire_after_days": null,
        "expire_after_views": null,
        "deletable_by_viewer": false,
        "retrieval_step": false,
        ...
      }
  EOS
  def show
  end

  api :POST, "/p.json", "Create a new push."
  param :password, Hash, "Push details", required: true do
    param :payload, String, desc: "The URL encoded password or secret text to share.", required: true
    param :passphrase, String, desc: "Require recipients to enter this passphrase to view the created push."
    param :name, String, desc: "Visible only to the push creator.", allow_blank: true
    param :note, String, desc: "If authenticated, the URL encoded note for this push.  Visible only to the push creator.", allow_blank: true
    param :expire_after_days, Integer, desc: "Expire secret link and delete after this many days."
    param :expire_after_views, Integer, desc: "Expire secret link and delete after this many views."
    param :deletable_by_viewer, %w[true false], desc: "Allow users to delete passwords once retrieved."
    param :retrieval_step, %w[true false], desc: "Helps to avoid chat systems and URL scanners from eating up views."
  end
  param :account_id, Integer, desc: "The account ID to associate the push with. See: https://docs.pwpush.com/docs/json-api/#multiple-accounts", required: false
  formats ["JSON"]
  description <<-EOS
    == Creating a New Push

    Creates a new push (secret URL) containing the provided payload.

    === Required Parameters

    The push must be created with a payload parameter containing the secret content.
    All other parameters are optional and will use system defaults if not specified.

    === Expiration Settings

    Pushes can be configured to expire after:

    * A number of views (expire_after_views)
    * A number of days (expire_after_days)
    * Both views and days (first trigger wins)

    === Security Options

    * Passphrase protection requires viewers to enter a secret phrase
    * Retrieval step helps prevent automated URL scanners from burning views
    * Deletable by viewer allows recipients to manually expire the push

    == Example Request

      curl -X POST \\
        -H "Authorization: Bearer MyAPIToken" \\
        -H "Content-Type: application/json" \\
        -d '{"password": {"payload": "secret_text"}}' \\
        https://pwpush.com/p.json

    == Example Response

      {
        "url_token": "fkwjfvhall92",
        "created_at": "2023-10-20T15:32:01Z",
        "expires_at": "2023-10-20T15:32:01Z",
        "views_remaining": 10,
        "passphrase": null,
        "note": null,
        ...
      }
  EOS
  def create
  end

  api :GET, "/p/:url_token/preview.json", "Helper endpoint to retrieve the fully qualified secret URL of a push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["JSON"]
  description <<-EOS
    == Preview a Push

    This method retrieves the preview URL of a push.  This is useful for getting the
    fully qualified URL of a push before sharing it with others.

    === Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/p/fk27vnslkd/preview.json

    === Example Response

      {
        "url": "https://pwpush.com/p/fk27vnslkd"
      }
  EOS
  def preview
  end

  api :GET, "/p/:url_token/audit.json", "Retrieve the audit log for a push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["JSON"]
  description <<-EOS
    == Push Audit Log Retrieval

    Returns the audit log for a push, containing an array of view events with metadata including:
    - IP address of viewer
    - User agent
    - Referrer URL
    - Timestamp
    - Event type (view, failed_view, expire, etc)

    Authentication is required. Only the owner of the push can retrieve its audit log.
    Requests for pushes not owned by the authenticated user will receive a 403 Forbidden response.

    == Example Request

      curl -X GET \\
        -H "X-User-Email: user@example.com" \\
        -H "X-User-Token: MyAPIToken" \\
        https://pwpush.com/p/fk27vnslkd/audit.json

    == Example Response

      {
        "views": [
          {
            "ip": "x.x.x.x",
            "user_agent": "Mozilla/5.0...",
            "referrer": "https://example.com",
            "created_at": "2023-10-20T15:32:01Z",
            "successful": true,
            ...
          }
        ]
      }
  EOS
  def audit
  end

  api :DELETE, "/p/:url_token.json", "Expire a push: delete the payload and expire the secret URL."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["JSON"]
  description <<-EOS
    == Push Expiration

    Expires a push immediately.  Must be authenticated & owner of the push _or_ the push must
    have been created with _deleteable_by_viewer_.

    == Example Request

      curl -X DELETE \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/p/fkwjfvhall92.json

    == Example Response

      {
        "expired": true,
        "expired_on": "2024-12-10T15:32:01Z"
      }
  EOS
  def destroy
  end

  api :GET, "/p/active.json", "Retrieve your active pushes."
  formats ["JSON"]
  description <<-EOS
    == Active Pushes Retrieval

    Returns the list of pushes for your account that are still active.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/p/active.json

    == Example Response

        [
          {
            "url_token": "fkwjfvhall92",
            "created_at": "2023-10-20T15:32:01Z",
            "name": null,
            "expire_after_days": 7,
            "expire_after_views": 1,
            "expired": false,
            "days_remaining": 7,
            "views_remaining": 1,
            ...
          },
          ...
        ]
  EOS
  def active
  end

  api :GET, "/p/expired.json", "Retrieve your expired pushes."
  formats ["JSON"]
  description <<-EOS
    == Expired Pushes Retrieval

    Returns the list of pushes for your account that have expired.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/p/expired.json

    == Example Response

      [
        {
          "url_token": "fkwjfvhall92",
          "created_at": "2023-10-20T15:32:01Z",
          "expires_on": "2023-10-23T15:32:01Z",
          "expire_after_days": 7,
          "expire_after_views": 1,
          "expired": true,
          ...
        },
        ...
      ]
  EOS
  def expired
  end
end
