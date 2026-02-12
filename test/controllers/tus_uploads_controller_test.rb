# frozen_string_literal: true

require "test_helper"

class TusUploadsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Settings.files.storage = "local"
    Settings.files.use_tus_uploads = true
    @user = users(:luca)
    @user.confirm
    sign_in @user
  end

  # ---- POST create ----

  test "POST create returns 201 and Location" do
    post uploads_path,
      headers: {"Upload-Length" => "7", "Upload-Metadata" => "filename dGVzdC50eHQ="}
    assert_response :created
    assert response.headers["Location"].present?
    assert_equal "0", response.headers["Upload-Offset"]
    assert_equal "7", response.headers["Upload-Length"]
  end

  test "POST create without Upload-Length returns 400" do
    post uploads_path, headers: {}
    assert_response :bad_request
  end

  test "POST create with empty Upload-Length returns 400" do
    post uploads_path, headers: {"Upload-Length" => ""}
    assert_response :bad_request
  end

  test "POST create with zero Upload-Length returns 400" do
    post uploads_path, headers: {"Upload-Length" => "0"}
    assert_response :bad_request
  end

  test "POST create with negative Upload-Length returns 400" do
    post uploads_path, headers: {"Upload-Length" => "-1"}
    assert_response :bad_request
  end

  test "POST create with Upload-Length exceeding max returns 413" do
    Settings.files.max_tus_upload_size = 10
    post uploads_path, headers: {"Upload-Length" => "11"}
    assert_response :payload_too_large
  ensure
    Settings.files.max_tus_upload_size = 107374182400
  end

  test "POST create with Upload-Length equal to max succeeds" do
    Settings.files.max_tus_upload_size = 4
    post uploads_path, headers: {"Upload-Length" => "4"}
    assert_response :created
  ensure
    Settings.files.max_tus_upload_size = 107374182400
  end

  test "POST create when TUS disabled returns 404" do
    Settings.files.use_tus_uploads = false
    post uploads_path, headers: {"Upload-Length" => "7"}
    assert_response :not_found
  ensure
    Settings.files.use_tus_uploads = true
  end

  test "POST create requires auth" do
    sign_out @user
    post uploads_path, headers: {"Upload-Length" => "7"}
    assert_response :redirect
  end

  test "POST create without Upload-Metadata creates upload" do
    post uploads_path, headers: {"Upload-Length" => "3"}
    assert_response :created
    upload_id = upload_id_from_location(response.headers["Location"])
    patch upload_path(upload_id),
      params: "xyz",
      headers: {"Content-Type" => "application/offset+octet-stream", "Upload-Offset" => "0"}
    assert_response :no_content
    signed_id = response.headers["X-Signed-Id"]
    blob = ActiveStorage::Blob.find_signed(signed_id)
    assert_equal "upload", blob.filename.to_s
    assert_equal "application/octet-stream", blob.content_type
    assert_equal 3, blob.byte_size
  end

  test "POST create with invalid base64 in Upload-Metadata does not crash" do
    post uploads_path,
      headers: {"Upload-Length" => "1", "Upload-Metadata" => "filename not-valid-base64!!"}
    assert_response :created
  end

  # ---- HEAD update ----

  test "HEAD returns offset and length" do
    post uploads_path, headers: {"Upload-Length" => "10"}
    assert_response :created
    upload_id = upload_id_from_location(response.headers["Location"])

    head upload_path(upload_id)
    assert_response :no_content
    assert_equal "0", response.headers["Upload-Offset"]
    assert_equal "10", response.headers["Upload-Length"]
  end

  test "HEAD on non-existent upload returns 404" do
    head upload_path("nonexistent-id-12345")
    assert_response :not_found
  end

  test "HEAD requires auth" do
    post uploads_path, headers: {"Upload-Length" => "5"}
    assert_response :created
    upload_id = upload_id_from_location(response.headers["Location"])
    sign_out @user
    head upload_path(upload_id)
    assert_response :redirect
  end

  test "HEAD after partial PATCH returns current offset" do
    post uploads_path, headers: {"Upload-Length" => "6"}
    assert_response :created
    upload_id = upload_id_from_location(response.headers["Location"])
    patch upload_path(upload_id),
      params: "ab",
      headers: {"Content-Type" => "application/offset+octet-stream", "Upload-Offset" => "0"}
    assert_response :no_content
    head upload_path(upload_id)
    assert_response :no_content
    assert_equal "2", response.headers["Upload-Offset"]
    assert_equal "6", response.headers["Upload-Length"]
  end

  # ---- PATCH update ----

  test "full TUS flow creates blob and returns X-Signed-Id" do
    post uploads_path,
      headers: {"Upload-Length" => "5", "Upload-Metadata" => "filename aC50eHQ=,filetype dGV4dC9wbGFpbg=="}
    assert_response :created
    upload_id = upload_id_from_location(response.headers["Location"])

    patch upload_path(upload_id),
      params: "hello",
      headers: {"Content-Type" => "application/offset+octet-stream", "Upload-Offset" => "0"}
    assert_response :no_content
    assert response.headers["X-Signed-Id"].present?, "Expected X-Signed-Id in response"
    signed_id = response.headers["X-Signed-Id"]
    blob = ActiveStorage::Blob.find_signed(signed_id)
    assert blob.present?
    assert_equal "h.txt", blob.filename.to_s
    assert_equal 5, blob.byte_size
  end

  test "chunked upload in two PATCHes returns X-Signed-Id on final chunk" do
    post uploads_path,
      headers: {"Upload-Length" => "6", "Upload-Metadata" => "filename dHdvLnR4dA=="}
    assert_response :created
    upload_id = upload_id_from_location(response.headers["Location"])

    patch upload_path(upload_id),
      params: "hel",
      headers: {"Content-Type" => "application/offset+octet-stream", "Upload-Offset" => "0"}
    assert_response :no_content
    assert_nil response.headers["X-Signed-Id"]
    assert_equal "3", response.headers["Upload-Offset"]

    patch upload_path(upload_id),
      params: "lo!",
      headers: {"Content-Type" => "application/offset+octet-stream", "Upload-Offset" => "3"}
    assert_response :no_content
    assert response.headers["X-Signed-Id"].present?
    blob = ActiveStorage::Blob.find_signed(response.headers["X-Signed-Id"])
    assert_equal 6, blob.byte_size
    assert_equal "two.txt", blob.filename.to_s
  end

  test "PATCH with wrong offset returns 409 and current offset" do
    post uploads_path, headers: {"Upload-Length" => "3"}
    assert_response :created
    upload_id = upload_id_from_location(response.headers["Location"])

    patch upload_path(upload_id),
      params: "ab",
      headers: {"Content-Type" => "application/offset+octet-stream", "Upload-Offset" => "1"}
    assert_response :conflict
    assert_equal "0", response.headers["Upload-Offset"]
  end

  test "PATCH without Upload-Offset returns 400" do
    post uploads_path, headers: {"Upload-Length" => "2"}
    assert_response :created
    upload_id = upload_id_from_location(response.headers["Location"])

    patch upload_path(upload_id),
      params: "ab",
      headers: {"Content-Type" => "application/offset+octet-stream"}
    assert_response :bad_request
  end

  test "PATCH on non-existent upload returns 404" do
    patch upload_path("nonexistent-id-12345"),
      params: "x",
      headers: {"Content-Type" => "application/offset+octet-stream", "Upload-Offset" => "0"}
    assert_response :not_found
  end

  test "PATCH on already completed upload returns 410" do
    post uploads_path, headers: {"Upload-Length" => "1"}
    assert_response :created
    upload_id = upload_id_from_location(response.headers["Location"])
    patch upload_path(upload_id),
      params: "x",
      headers: {"Content-Type" => "application/offset+octet-stream", "Upload-Offset" => "0"}
    assert_response :no_content
    # Upload was finalized and destroyed. Create a new upload with same id that is complete
    # but not finalized (simulates race or duplicate final chunk).
    store = TusUploadStore.new(upload_id)
    store.create!(upload_length: 1, filename: "x.txt")
    store.append_chunk!(offset: 0, io: StringIO.new("x"))
    patch upload_path(upload_id),
      params: "y",
      headers: {"Content-Type" => "application/offset+octet-stream", "Upload-Offset" => "1"}
    assert_response :gone
  end

  test "PUT to upload URL returns 404 (only PATCH and HEAD are routed)" do
    post uploads_path, headers: {"Upload-Length" => "1"}
    assert_response :created
    upload_id = upload_id_from_location(response.headers["Location"])
    put upload_path(upload_id),
      params: "x",
      headers: {"Content-Type" => "application/offset+octet-stream", "Upload-Offset" => "0"}
    assert_response :not_found
  end

  test "PATCH requires auth" do
    post uploads_path, headers: {"Upload-Length" => "2"}
    assert_response :created
    upload_id = upload_id_from_location(response.headers["Location"])
    sign_out @user
    patch upload_path(upload_id),
      params: "ab",
      headers: {"Content-Type" => "application/offset+octet-stream", "Upload-Offset" => "0"}
    assert_response :redirect
  end

  test "PATCH empty body when upload_length 1 leaves incomplete" do
    post uploads_path, headers: {"Upload-Length" => "1"}
    assert_response :created
    upload_id = upload_id_from_location(response.headers["Location"])
    patch upload_path(upload_id),
      params: "",
      headers: {"Content-Type" => "application/offset+octet-stream", "Upload-Offset" => "0"}
    assert_response :no_content
    assert_equal "0", response.headers["Upload-Offset"]
    assert_nil response.headers["X-Signed-Id"]
  end

  private

  def upload_id_from_location(location)
    return nil if location.blank?
    File.basename(URI.parse(location).path)
  end
end
