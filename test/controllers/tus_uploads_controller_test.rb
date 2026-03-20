# frozen_string_literal: true

require "test_helper"

class TusUploadsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include TusUploadTestSettings

  setup do
    store_tus_related_settings
    Settings.disable_logins = false
    Settings.enable_file_pushes = true
    Settings.files.storage = "local"
    @user = users(:luca)
    confirm_user(@user)
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

  test "POST create when logins disabled returns 404" do
    Settings.disable_logins = true
    Settings.enable_file_pushes = true
    post uploads_path, headers: {"Upload-Length" => "7"}
    assert_response :not_found
  end

  test "POST create requires auth" do
    sign_out @user
    post uploads_path, headers: {"Upload-Length" => "7"}
    assert_response :redirect
  end

  test "POST create with cross-origin Origin returns 403" do
    post uploads_path,
      headers: {"Upload-Length" => "7", "Origin" => "https://evil.example.com"}
    assert_response :forbidden
  end

  test "POST create with cross-origin Referer returns 403" do
    post uploads_path,
      headers: {"Upload-Length" => "7", "Referer" => "https://evil.example.com/malicious"}
    assert_response :forbidden
  end

  test "POST create without Origin or Referer succeeds (same-origin)" do
    post uploads_path, headers: {"Upload-Length" => "7"}
    assert_response :created
  end

  test "PATCH with cross-origin Origin returns 403" do
    upload_id = create_tus_upload(upload_length: 3)
    patch upload_path(upload_id),
      params: "xyz",
      headers: {
        "Content-Type" => "application/offset+octet-stream",
        "Upload-Offset" => "0",
        "Origin" => "https://evil.example.com"
      }
    assert_response :forbidden
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

  test "POST create sets Location as relative path so client uses same origin for PATCH" do
    create_tus_upload(upload_length: 1)
    location = response.headers["Location"]
    assert location.present?, "Location header must be set"
    assert_match(/\A\/uploads\/[^\s\/]+\z/, location, "Location must be relative path /uploads/:id (same-origin for proxy/Docker)")
    assert upload_id_from_location(location).present?, "Location must contain upload id"
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

  test "Upload-Metadata filetype text/html is rejected and blob gets application/octet-stream" do
    # filetype "text/html" base64 = dGV4dC9odG1s
    upload_id = create_tus_upload(
      upload_length: 2,
      upload_metadata: "filename Zm9v.html,filetype dGV4dC9odG1s"
    )
    patch_tus_chunk(upload_id, "ab")
    assert_response :no_content
    blob = ActiveStorage::Blob.find_signed(response.headers["X-Signed-Id"])
    assert_equal "application/octet-stream", blob.content_type, "Blocked filetype must not be stored"
  end

  test "Upload-Metadata filetype text/javascript is rejected" do
    # filetype "text/javascript" base64 = dGV4dC9qYXZhc2NyaXB0
    upload_id = create_tus_upload(
      upload_length: 1,
      upload_metadata: "filetype dGV4dC9qYXZhc2NyaXB0"
    )
    patch_tus_chunk(upload_id, "x")
    assert_response :no_content
    blob = ActiveStorage::Blob.find_signed(response.headers["X-Signed-Id"])
    assert_equal "application/octet-stream", blob.content_type
  end

  # ---- Upload-Metadata filename sanitization ----

  test "Upload-Metadata filename path traversal is sanitized to basename" do
    # "../../../etc/passwd" -> File.basename -> "passwd"
    upload_id = create_tus_upload(
      upload_length: 3,
      upload_metadata: "filename #{Base64.strict_encode64('../../../etc/passwd')}"
    )
    patch_tus_chunk(upload_id, "xyz")
    assert_response :no_content
    blob = ActiveStorage::Blob.find_signed(response.headers["X-Signed-Id"])
    assert_equal "passwd", blob.filename.to_s
  end

  test "Upload-Metadata filename with subdir path uses basename only" do
    upload_id = create_tus_upload(
      upload_length: 2,
      upload_metadata: "filename #{Base64.strict_encode64('foo/bar.txt')}"
    )
    patch_tus_chunk(upload_id, "ab")
    assert_response :no_content
    blob = ActiveStorage::Blob.find_signed(response.headers["X-Signed-Id"])
    assert_equal "bar.txt", blob.filename.to_s
  end

  test "Upload-Metadata filename special characters replaced with underscore" do
    # "a<b>c.txt" -> "a_b_c.txt"
    upload_id = create_tus_upload(
      upload_length: 1,
      upload_metadata: "filename #{Base64.strict_encode64('a<b>c.txt')}"
    )
    patch_tus_chunk(upload_id, "x")
    assert_response :no_content
    blob = ActiveStorage::Blob.find_signed(response.headers["X-Signed-Id"])
    assert_equal "a_b_c.txt", blob.filename.to_s
  end

  test "Upload-Metadata filename spaces replaced with underscore" do
    upload_id = create_tus_upload(
      upload_length: 2,
      upload_metadata: "filename #{Base64.strict_encode64('file name.txt')}"
    )
    patch_tus_chunk(upload_id, "ab")
    assert_response :no_content
    blob = ActiveStorage::Blob.find_signed(response.headers["X-Signed-Id"])
    assert_equal "file_name.txt", blob.filename.to_s
  end

  test "Upload-Metadata filename blank or whitespace only yields default blob filename" do
    upload_id = create_tus_upload(
      upload_length: 2,
      upload_metadata: "filename #{Base64.strict_encode64('   ')}"
    )
    patch_tus_chunk(upload_id, "ab")
    assert_response :no_content
    blob = ActiveStorage::Blob.find_signed(response.headers["X-Signed-Id"])
    assert_equal "upload", blob.filename.to_s
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

  test "PATCH with chunk larger than tus_chunk_size returns 413" do
    Settings.files.tus_chunk_size = 5 # 5 bytes limit
    upload_id = create_tus_upload(upload_length: 10)
    patch_tus_chunk(upload_id, "abcdef")
    assert_response :payload_too_large
  end

  # When Content-Length is absent (e.g. chunked transfer encoding), the controller cannot
  # reject oversized payloads by header; the store caps bytes read per PATCH via max_bytes.
  # This test verifies that path: only max_chunk bytes are written even when body is larger.
  test "PATCH without Content-Length (chunked) writes at most tus_chunk_size bytes" do
    Settings.files.tus_chunk_size = 3 # 3 bytes per chunk
    upload_id = create_tus_upload(upload_length: 10)
    body = "abcdefghij"
    patch upload_path(upload_id),
      params: body,
      headers: {"Content-Type" => "application/offset+octet-stream", "Upload-Offset" => "0"},
      env: { "CONTENT_LENGTH" => nil }
    assert_response :no_content, "PATCH without Content-Length should succeed and cap at max_chunk"
    assert_equal "3", response.headers["Upload-Offset"], "Only 3 bytes (tus_chunk_size) must be accepted"
    store = TusUploadStore.new(upload_id)
    assert store.exist?
    assert_equal 3, File.size(store.data_path), "Store must not write more than max_chunk when Content-Length absent"
  end

  test "PATCH retry after finalize returns 204 with X-Signed-Id from cache" do
    # Test uses a real cache so finalized_upload_cache_write is persisted (test env uses :null_store by default)
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    begin
      upload_id = create_tus_upload(upload_length: 3)
      patch_tus_chunk(upload_id, "abc")
      assert_response :no_content
      first_signed_id = response.headers["X-Signed-Id"]
      assert first_signed_id.present?, "First PATCH must return X-Signed-Id"
      # Retry final chunk (upload dir already removed by finalize)
      patch_tus_chunk(upload_id, "abc", offset: 0)
      assert_response :no_content, "Retry of final PATCH should succeed"
      assert_equal first_signed_id, response.headers["X-Signed-Id"], "Retry should return same X-Signed-Id"
      assert_equal "3", response.headers["Upload-Offset"]
      assert_equal "3", response.headers["Upload-Length"]
    ensure
      Rails.cache = original_cache
    end
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

  test "PATCH with empty Upload-Offset header returns 400" do
    upload_id = create_tus_upload(upload_length: 2)
    patch upload_path(upload_id),
      params: "ab",
      headers: {"Content-Type" => "application/offset+octet-stream", "Upload-Offset" => ""}
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

  test "PATCH when finalize_to_blob! raises NotFound returns 404" do
    upload_id = create_tus_upload(upload_length: 3)
    store = TusUploadStore.new(upload_id)
    store.stub :finalize_to_blob!, -> { raise TusUploadStore::NotFound } do
      TusUploadStore.stub :new, store do
        patch_tus_chunk(upload_id, "abc")
        assert_response :not_found
      end
    end
  ensure
    store&.destroy! if defined?(store) && store.respond_to?(:exist?) && store.exist?
  end

  test "PATCH when finalize_to_blob! raises ArgumentError upload not complete returns 410" do
    upload_id = create_tus_upload(upload_length: 3)
    store = TusUploadStore.new(upload_id)
    store.stub :finalize_to_blob!, -> { raise ArgumentError, "upload not complete" } do
      TusUploadStore.stub :new, store do
        patch_tus_chunk(upload_id, "abc")
        assert_response :gone
      end
    end
  ensure
    store&.destroy! if defined?(store) && store.respond_to?(:exist?) && store.exist?
  end

  # ---- session tus_active_upload_ids (block push while uploads in progress) ----

  test "POST create registers upload id in session so push create is blocked" do
    create_tus_upload(upload_length: 3)
    # Without finalizing, try to create a file push
    post pushes_path, params: { push: { kind: "file", payload: "x" } }
    assert_response :conflict
    assert_match(/wait.*upload|upload.*finish/i, response.body, "Response must tell user to wait for uploads")
  end

  test "DELETE upload releases session so push create succeeds after abandon" do
    upload_id = create_tus_upload(upload_length: 10)
    post pushes_path, params: { push: { kind: "file", payload: "x" } }
    assert_response :conflict

    delete upload_path(upload_id)
    assert_response :no_content

    post pushes_path, params: { push: { kind: "file", payload: "x" } }
    assert_response :redirect
  end

  test "DELETE upload returns 404 when id is not tracked in session" do
    upload_id = create_tus_upload(upload_length: 3)
    delete upload_path(upload_id)
    assert_response :no_content

    delete upload_path(upload_id)
    assert_response :not_found
  end

  test "finalizing upload clears session tracking so push create succeeds" do
    upload_id = create_tus_upload(upload_length: 3)
    patch_tus_chunk(upload_id, "xyz")
    assert_response :no_content
    signed_id = response.headers["X-Signed-Id"]
    assert signed_id.present?, "Finalize must return X-Signed-Id"
    post pushes_path, params: { push: { kind: "file", payload: "msg", files: [signed_id] } }
    assert_response :redirect, "Push create must succeed after upload finalized"
  end

  test "push update (file) returns 409 when TUS upload in progress" do
    push = Push.create!(kind: "file", user: @user)
    push.files.attach(io: StringIO.new("a"), filename: "a.txt", content_type: "text/plain")
    create_tus_upload(upload_length: 1)
    patch push_path(push), params: { push: { name: "Updated" } }
    assert_response :conflict
    assert_match(/wait.*upload|upload.*finish/i, response.body)
  end

  test "visiting new push form resets session tus upload tracking" do
    create_tus_upload(upload_length: 3)
    
    # Normally this would be blocked, but visiting new page resets it
    get new_push_path(tab: "files")
    assert_response :success
    
    post pushes_path, params: { push: { kind: "file", payload: "x" } }
    assert_response :redirect
  end

  test "visiting edit push form resets session tus upload tracking" do
    push = Push.create!(kind: "file", user: @user)
    push.files.attach(io: StringIO.new("a"), filename: "a.txt", content_type: "text/plain")

    create_tus_upload(upload_length: 3)
    
    # Normally this would be blocked, but visiting edit page resets it
    get edit_push_path(push)
    assert_response :success

    patch push_path(push), params: { push: { name: "Updated" } }
    assert_response :redirect
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