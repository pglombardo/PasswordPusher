# frozen_string_literal: true

require "securerandom"

class Api::V1::FilePushesController < Api::BaseController
  helper FilePushesHelper

  before_action :set_push, only: %i[show preview audit destroy]

  resource_description do
    name "File Pushes"
    short "Interact directly with file pushes."
  end

  api :GET, "/f/:url_token.json", "Retrieve a file push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["JSON"]
  description <<-EOS
    == File Push Retrieval

    Retrieves a file push including it's payload and details.  If the push is still active,
    this will burn a view and the transaction will be logged in the push audit log.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/f/fk27vnslkd.json

    == Example Response

      {
        "expire_after_days": 2,
        "expire_after_views": 5,
        "expired": false,
        "url_token": "quyul5r5w18",
        "files": '{"file1.extension":"/pfb/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MywicHVyIjoiYmxvYl9pZCJ9fQ==--acf3b59f1884a16ef5d178848c32af856338064f/file1.extension","file2.extension":"/pfb/redirect/eyJfcmFpbHMiOnsiZGF0YSI6NCwicHVyIjoiYmxvYl9pZCJ9fQ==--34b10a5eca9026f8cc41bbd71c4d684abbe607bf/file2.extension"}'
        ...
      }

      Note: The files attached to the push are listed as a string of JSON with filenames and paths only.  This will be improved in v2 of the API.

      {
        "file1.extension": "/pfb/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MywicHVyIjoiYmxvYl9pZCJ9fQ==--acf3b59f1884a16ef5d178848c32af856338064f/file1.extension",
        "file2.extension": "/pfb/redirect/eyJfcmFpbHMiOnsiZGF0YSI6NCwicHVyIjoiYmxvYl9pZCJ9fQ==--34b10a5eca9026f8cc41bbd71c4d684abbe607bf/file2.extension"
      }
  EOS
  def show
  end

  api :POST, "/f.json", "Create a new file push."
  param :file_push, Hash, "Push details", required: true do
    param :payload, String, desc: "The URL encoded secret text to share.", required: true
    param :passphrase, String, desc: "Require recipients to enter this passphrase to view the created push."
    param :name, String, desc: "Visible only to the push creator.", allow_blank: true
    param :note, String,
      desc: "If authenticated, the URL encoded note for this push.  Visible only to the push creator.", allow_blank: true
    param :expire_after_days, Integer, desc: "Expire secret link and delete after this many days."
    param :expire_after_views, Integer, desc: "Expire secret link and delete after this many views."
    param :deletable_by_viewer, %w[true false], desc: "Allow users to delete the push once retrieved."
    param :retrieval_step, %w[true false],
      desc: "Helps to avoid chat systems and URL scanners from eating up views."
  end
  formats ["JSON"]
  description <<-EOS
    == File Push Creation

    Creates a new file push with the given payload and files.

    == Example Request

      curl -X POST \\
        -H "Authorization: Bearer MyAPIToken" \\
        -F "file_push[files][]=@/path/to/file/file1.extension" \\
        -F "file_push[files][]=@/path/to/file/file2.extension" \\
        https://pwpush.com/f.json

    == Example Response

      {
        "url_token": "quyul5r5w18",
        "created_at": "2023-10-20T15:32:01Z",
        "expire_after_days": 2,
        "expire_after_views": 5,
        ...
      }
  EOS
  def create
  end

  api :GET, "/f/:url_token/preview.json", "Helper endpoint to retrieve the fully qualified secret URL of a push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["JSON"]
  description <<-EOS
    == File Push Preview

    Retrieves the fully qualified secret URL of a push.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/f/fk27vnslkd/preview.json

    == Example Response

      {
        "url": "https://pwpush.com/f/fk27vnslkd"
      }
  EOS
  def preview
  end

  api :GET, "/f/:url_token/audit.json", "Retrieve the audit log for a push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["JSON"]
  description <<-EOS
    == File Push Audit

    Retrieves the audit log for a push.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/f/fk27vnslkd/audit.json

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

  api :DELETE, "/f/:url_token.json", "Expire a push: delete the files, payload and expire the secret URL."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["JSON"]
  description <<-EOS
    == File Push Expiration

    Expires a push immediately.  Must be authenticated & owner of the push _or_ the push must
    have been created with _deleteable_by_viewer_.

    == Example Request

      curl -X DELETE \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/f/fkwjfvhall92.json

    == Example Response

      {
        "expired": true,
        "expired_on": "2023-10-23T15:32:01Z",
        ...
      }
  EOS
  def destroy
  end

  api :GET, "/f/active.json", "Retrieve your active file pushes."
  formats ["JSON"]
  description <<-EOS
    == Active File Pushes Retrieval

    Returns the list of file pushes that you previously pushed which are still active.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/f/active.json

    == Example Response

      [
        {
          "url_token": "fkwjfvhall92",
          "created_at": "2023-10-20T15:32:01Z",
          "expires_on": "2023-10-23T15:32:01Z",
          "name": null,
          ...
        },
        ...
      ]
  EOS
  def active
  end

  api :GET, "/f/expired.json", "Retrieve your expired file pushes."
  formats ["JSON"]
  description <<-EOS
    == Expired File Pushes Retrieval

    Returns the list of expired file pushes.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/f/expired.json

    == Example Response

      [
        {
          "url_token": "fkwjfvhall92",
          "created_at": "2023-10-20T15:32:01Z",
          "expires_on": "2023-10-23T15:32:01Z",
          ...
        },
      ]
  EOS
  def expired
  end
end
