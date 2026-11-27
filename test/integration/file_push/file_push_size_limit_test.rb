# frozen_string_literal: true

require "test_helper"

class FilePushSizeLimitTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!
    @luca = users(:luca)
  end

  teardown do
    Settings.reload!
    Rails.application.reload_routes!
  end

  def test_model_rejects_oversized_attachment
    Settings.files.max_file_size = "10"
    push = Push.new(kind: "file")
    push.files.attach(fixture_file_upload("monkey.png", "image/png"))

    assert_not push.valid?
    assert push.errors[:files].any? { |msg| msg.include?("too large") }
  end

  def test_legacy_json_api_rejects_oversized_file
    Settings.files.max_file_size = "10"

    post file_pushes_path(format: :json),
      params: {
        file_push: {
          payload: "Message",
          files: [fixture_file_upload("monkey.png", "image/png")]
        }
      },
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}

    assert_response :unprocessable_content
    body = JSON.parse(@response.body)
    assert Array(body["files"]).any? { |msg| msg.include?("too large") }
  end

  def test_api_v2_rejects_oversized_file
    Settings.files.max_file_size = "10"

    post "/api/v2/pushes",
      params: {
        push: {
          kind: "file",
          payload: "Message",
          files: [fixture_file_upload("monkey.png", "image/png")]
        }
      },
      headers: {"Authorization" => "Bearer #{@luca.authentication_token}"}

    assert_response :unprocessable_content
    body = JSON.parse(@response.body)
    assert Array(body["files"]).any? { |msg| msg.include?("too large") }
  end

  def test_api_v2_allows_file_under_the_limit
    Settings.files.max_file_size = "10MB"

    post "/api/v2/pushes",
      params: {
        push: {
          kind: "file",
          payload: "Message",
          files: [fixture_file_upload("test-file.txt", "text/plain")]
        }
      },
      headers: {"Authorization" => "Bearer #{@luca.authentication_token}"}

    assert_response :created
  end

  def test_new_file_form_shows_configured_max_size
    Settings.files.max_file_size = "25MB"
    sign_in @luca

    get new_push_path(tab: "files")
    assert_response :success
    assert_includes @response.body, "Maximum size per file is 25MB."
    assert_includes @response.body, "data-multi-upload-max-file-size-value"
  end
end
