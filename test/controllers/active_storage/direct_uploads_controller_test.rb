# frozen_string_literal: true

require "test_helper"

class ActiveStorage::DirectUploadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Settings.enable_file_pushes = true
  end

  teardown do
    Settings.reload!
  end

  def test_rejects_oversized_direct_upload_blob_create
    Settings.files.max_file_size = "1KB"

    assert_no_difference -> { ActiveStorage::Blob.count } do
      post rails_direct_uploads_url, params: blob_params(byte_size: 20.kilobytes), as: :json
    end

    assert_response :unprocessable_content
    body = JSON.parse(@response.body)
    assert_includes body["error"], "too large"
    assert_includes body["error"], "1KB"
  end

  def test_allows_direct_upload_blob_create_under_the_limit
    Settings.files.max_file_size = "1MB"

    assert_difference -> { ActiveStorage::Blob.count }, 1 do
      post rails_direct_uploads_url, params: blob_params(byte_size: 100), as: :json
    end

    assert_response :success
    body = JSON.parse(@response.body)
    assert body["direct_upload"]["url"].present?
  end

  def test_direct_upload_url_uses_configured_expiry
    Settings.files.direct_upload_urls_expire_in = "90 minutes"

    post rails_direct_uploads_url, params: blob_params(byte_size: 100), as: :json
    assert_response :success

    blob = ActiveStorage::Blob.last
    captured = nil
    blob.service.stub :url_for_direct_upload, ->(*_args, **kwargs) {
      captured = kwargs[:expires_in]
      "https://example.test/upload"
    } do
      blob.service_url_for_direct_upload
    end

    assert_equal 90.minutes, captured
  end

  def test_download_url_uses_configured_expiry
    Settings.files.blob_urls_expire_in = "12 minutes"

    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("hello"),
      filename: "hello.txt",
      content_type: "text/plain"
    )

    captured = nil
    blob.service.stub :url, ->(*_args, **kwargs) {
      captured = kwargs[:expires_in]
      "https://example.test/download"
    } do
      blob.url
    end

    assert_equal 12.minutes, captured
  end

  def test_rails_blob_url_honors_configured_download_expiry
    Settings.files.blob_urls_expire_in = "10 minutes"
    assert_equal 10.minutes, ActiveStorage.urls_expire_in

    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("hello"),
      filename: "hello.txt",
      content_type: "text/plain"
    )

    path = rails_blob_path(blob, only_path: true)

    travel 6.minutes do
      get path
      assert_response :redirect
    end

    travel 11.minutes do
      get path
      assert_response :not_found
    end
  end

  private

  def blob_params(byte_size:)
    {
      blob: {
        filename: "payload.bin",
        byte_size: byte_size,
        checksum: Digest::MD5.base64digest("x"),
        content_type: "application/octet-stream"
      }
    }
  end
end
