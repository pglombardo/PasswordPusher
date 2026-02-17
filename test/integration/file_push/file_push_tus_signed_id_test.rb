# frozen_string_literal: true

require "test_helper"

class FilePushTusSignedIdTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include TusUploadTestSettings

  setup do
    store_tus_related_settings
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Settings.files.storage = "local"
    Rails.application.reload_routes!
    @user = users(:luca)
    @user.confirm
    sign_in @user
  end

  teardown do
    sign_out :user
    restore_tus_related_settings
  end

  test "create file push with TUS signed_id attaches blob" do
    signed_id = complete_tus_upload(upload_length: 3, body: "abc", upload_metadata: "filename dGVzdC50eHQ=")
    assert signed_id.present?, "TUS upload should return signed id"

    post pushes_path, params: {
      push: {
        kind: "file",
        payload: "Message with TUS file",
        files: [signed_id]
      }
    }
    assert_response :redirect
    push = Push.order(created_at: :desc).first
    assert push.present?, "Push should be created"
    assert_redirected_to preview_push_path(push)
    assert push.file?
    assert push.files.attached?
    assert_equal 1, push.files.count
    blob = push.files.blobs.first
    assert_equal "test.txt", blob.filename.to_s
    assert_equal 3, blob.byte_size
  end

  test "update file push with TUS signed_id adds file" do
    push = Push.create!(kind: "file", name: "Edit me", user: @user)
    push.files.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test-file.txt")),
      filename: "test-file.txt",
      content_type: "text/plain"
    )
    assert_equal 1, push.files.count

    signed_id = complete_tus_upload(upload_length: 4, body: "xyz\n", upload_metadata: "filename c2Vjb25kLnR4dA==")
    assert signed_id.present?

    patch push_path(push), params: {
      push: {
        files: [signed_id]
      }
    }
    assert_response :redirect
    assert_redirected_to preview_push_path(push)

    push.reload
    assert_equal 2, push.files.count
    filenames = push.files.blobs.map(&:filename).map(&:to_s).sort
    assert_includes filenames, "second.txt"
    assert_includes filenames, "test-file.txt"
  end

  private

  def complete_tus_upload(upload_length:, body:, upload_metadata: nil)
    headers = {"Upload-Length" => upload_length.to_s}
    headers["Upload-Metadata"] = upload_metadata if upload_metadata.present?
    post uploads_path, headers: headers
    assert_response :created
    upload_id = File.basename(URI.parse(response.headers["Location"]).path)

    patch upload_path(upload_id),
      params: body,
      headers: {"Content-Type" => "application/offset+octet-stream", "Upload-Offset" => "0"}
    assert_response :no_content
    response.headers["X-Signed-Id"] || response.headers["x-signed-id"]
  end
end
