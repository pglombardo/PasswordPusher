# frozen_string_literal: true

require "test_helper"

class TusUploadsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include TusUploadTestSettings

  setup do
    store_tus_related_settings
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Settings.files.storage = "local"
    @user = users(:luca)
    @user.confirm
    sign_in @user
  end

  teardown do
    restore_tus_related_settings
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
  end

  test "POST create with Upload-Length equal to max succeeds" do
    Settings.files.max_tus_upload_size = 4
    post uploads_path, headers: {"Upload-Length" => "4"}
    assert_response :created
  end

  test "POST create when file pushes disabled returns 404" do
    Settings.enable_file_pushes = false
    post uploads_path, headers: {"Upload-Length" => "7"}
    assert_response :not_found
  end

  test "POST create requires auth" do
    sign_out @user
    post uploads_path, headers: {"Upload-Length" => "7"}
    assert_response :redirect
  end

  test "POST create without Upload-Metadata creates upload" do
    upload_id = create_tus_upload(upload_length: 3)
    patch_tus_chunk(upload_id, "xyz")
    assert_response :no_content
    blob = ActiveStorage::Blob.find_signed(response.headers["X-Signed-Id"])
    assert_equal "upload", blob.filename.to_s
    assert_equal "application/octet-stream", blob.content_type
    assert_equal 3, blob.byte_size
  end

  test "POST create with invalid base64 in Upload-Metadata does not crash" do
    post uploads_path,
      headers: {"Upload-Length" => "1", "Upload-Metadata" => "filename not-valid-base64!!"}
    assert_response :created
  end

  test "POST create sets Location with scheme, host and path" do
    create_tus_upload(upload_length: 1)
    location = response.headers["Location"]
    assert location.present?, "Location header must be set"
    uri = URI.parse(location)
    assert_includes %w[http https], uri.scheme, "Location must use http or https"
    assert uri.host.present?, "Location must include host"
    assert_match(/\A\/uploads\/[^\s\/]+\z/, uri.path, "Location path must be /uploads/:id")
    assert upload_id_from_location(location).present?, "Location must contain upload id"
  end

  test "POST create includes port in Location when port is not 80 or 443" do
    # Use Host header so request.host/port are unambiguous (avoids "localhost:3000:9090" in integration tests)
    post "http://localhost:#{non_standard_port}/uploads",
      headers: {"Upload-Length" => "1", "Host" => "localhost:#{non_standard_port}"}
    assert_response :created
    location = response.headers["Location"]
    assert location.present?
    assert_includes location, ":#{non_standard_port}", "Location must include non-standard port"
    uri = URI.parse(location)
    assert_equal non_standard_port.to_s, uri.port.to_s
  end

  test "Upload-Metadata filename and filetype are parsed and applied to blob" do
    # filename "report.pdf" = cmVwb3J0LnBkZg==, filetype "application/pdf" = YXBwbGljYXRpb24vcGRm
    upload_id = create_tus_upload(
      upload_length: 4,
      upload_metadata: "filename cmVwb3J0LnBkZg==,filetype YXBwbGljYXRpb24vcGRm"
    )
    patch_tus_chunk(upload_id, "data")
    assert_response :no_content
    assert response.headers["X-Signed-Id"].present?
    blob = ActiveStorage::Blob.find_signed(response.headers["X-Signed-Id"])
    assert_equal "report.pdf", blob.filename.to_s, "Filename from Upload-Metadata must be applied"
    assert_equal "application/pdf", blob.content_type, "Filetype from Upload-Metadata must be applied"
    assert_equal 4, blob.byte_size
  end

  # ---- HEAD update ----

  test "HEAD returns offset and length" do
    upload_id = create_tus_upload(upload_length: 10)
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
    upload_id = create_tus_upload(upload_length: 5)
    sign_out @user
    head upload_path(upload_id)
    assert_response :redirect
  end

  test "HEAD after partial PATCH returns current offset" do
    upload_id = create_tus_upload(upload_length: 6)
    patch_tus_chunk(upload_id, "ab")
    assert_response :no_content
    head upload_path(upload_id)
    assert_response :no_content
    assert_equal "2", response.headers["Upload-Offset"]
    assert_equal "6", response.headers["Upload-Length"]
  end

  # ---- PATCH update ----

  test "full TUS flow creates blob and returns X-Signed-Id" do
    upload_id = create_tus_upload(
      upload_length: 5,
      upload_metadata: "filename aC50eHQ=,filetype dGV4dC9wbGFpbg=="
    )
    patch_tus_chunk(upload_id, "hello")
    assert_response :no_content
    assert response.headers["X-Signed-Id"].present?, "Expected X-Signed-Id in response"
    blob = ActiveStorage::Blob.find_signed(response.headers["X-Signed-Id"])
    assert blob.present?
    assert_equal "h.txt", blob.filename.to_s
    assert_equal 5, blob.byte_size
  end

  test "chunked upload in two PATCHes returns X-Signed-Id on final chunk" do
    upload_id = create_tus_upload(upload_length: 6, upload_metadata: "filename dHdvLnR4dA==")
    patch_tus_chunk(upload_id, "hel")
    assert_response :no_content
    assert_nil response.headers["X-Signed-Id"]
    assert_equal "3", response.headers["Upload-Offset"]
    patch_tus_chunk(upload_id, "lo!", offset: 3)
    assert_response :no_content
    assert response.headers["X-Signed-Id"].present?
    blob = ActiveStorage::Blob.find_signed(response.headers["X-Signed-Id"])
    assert_equal 6, blob.byte_size
    assert_equal "two.txt", blob.filename.to_s
  end

  test "PATCH with wrong offset returns 409 and current offset" do
    upload_id = create_tus_upload(upload_length: 3)
    patch_tus_chunk(upload_id, "ab", offset: 1)
    assert_response :conflict
    assert_equal "0", response.headers["Upload-Offset"]
  end

  test "PATCH without Upload-Offset returns 400" do
    upload_id = create_tus_upload(upload_length: 2)
    patch_tus_chunk(upload_id, "ab", offset: nil)
    assert_response :bad_request
  end

  test "PATCH on non-existent upload returns 404" do
    patch upload_path("nonexistent-id-12345"),
      params: "x",
      headers: {"Content-Type" => "application/offset+octet-stream", "Upload-Offset" => "0"}
    assert_response :not_found
  end

  test "PATCH with invalid upload id (path traversal) returns 404" do
    patch upload_path("../../../etc/passwd"),
      params: "x",
      headers: {"Content-Type" => "application/offset+octet-stream", "Upload-Offset" => "0"}
    assert_response :not_found
  end

  test "HEAD with invalid upload id returns 404" do
    head upload_path("..")
    assert_response :not_found
  end

  test "PATCH on already completed upload returns 410" do
    upload_id = create_tus_upload(upload_length: 1)
    patch_tus_chunk(upload_id, "x")
    assert_response :no_content
    # Upload was finalized and destroyed. Create a new upload with same id that is complete
    # but not finalized (simulates race or duplicate final chunk).
    store = TusUploadStore.new(upload_id)
    store.create!(upload_length: 1, filename: "x.txt")
    store.append_chunk!(offset: 0, io: StringIO.new("x"))
    patch_tus_chunk(upload_id, "y", offset: 1)
    assert_response :gone
  end

  test "PUT to upload URL returns 404 (only PATCH and HEAD are routed)" do
    upload_id = create_tus_upload(upload_length: 1)
    put upload_path(upload_id),
      params: "x",
      headers: {"Content-Type" => "application/offset+octet-stream", "Upload-Offset" => "0"}
    assert_response :not_found
  end

  test "PATCH requires auth" do
    upload_id = create_tus_upload(upload_length: 2)
    sign_out @user
    patch_tus_chunk(upload_id, "ab")
    assert_response :redirect
  end

  test "PATCH empty body when upload_length 1 leaves incomplete" do
    upload_id = create_tus_upload(upload_length: 1)
    patch_tus_chunk(upload_id, "")
    assert_response :no_content
    assert_equal "0", response.headers["Upload-Offset"]
    assert_nil response.headers["X-Signed-Id"]
  end

  private

  # Creates a TUS upload via POST; returns the upload id from Location.
  def create_tus_upload(upload_length:, upload_metadata: nil)
    headers = {"Upload-Length" => upload_length.to_s}
    headers["Upload-Metadata"] = upload_metadata if upload_metadata.present?
    post uploads_path, headers: headers
    assert_response :created
    upload_id_from_location(response.headers["Location"])
  end

  # Appends a chunk via PATCH. Pass offset: nil to omit Upload-Offset (for 400 tests).
  def patch_tus_chunk(upload_id, body, offset: 0)
    headers = {"Content-Type" => "application/offset+octet-stream"}
    headers["Upload-Offset"] = offset.to_s if !offset.nil?
    patch upload_path(upload_id), params: body, headers: headers
  end

  def upload_id_from_location(location)
    return nil if location.blank?
    File.basename(URI.parse(location).path)
  end

  def host
    Rails.application.routes.default_url_options[:host] || "www.example.com"
  end

  def non_standard_port
    9_090
  end
end
