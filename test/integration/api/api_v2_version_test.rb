# frozen_string_literal: true

require "test_helper"

class ApiV2VersionTest < ActionDispatch::IntegrationTest
  def test_anonymous_version_endpoint
    get "/api/v2/version"
    assert_response :success

    json = JSON.parse(@response.body)
    assert_equal Version.current.to_s, json["application_version"]
    assert_equal "2.1", json["api_version"]
    assert_equal "oss", json["edition"]
    assert_equal expected_features, json["features"]
  end

  def test_authenticated_version_endpoint
    user = users(:one)

    get "/api/v2/version",
      headers: {
        "Accept" => "application/json",
        "Authorization" => "Bearer #{user.authentication_token}"
      }

    assert_response :success

    json = JSON.parse(@response.body)
    assert_equal Version.current.to_s, json["application_version"]
    assert_equal "2.1", json["api_version"]
    assert_equal "oss", json["edition"]
    assert_equal expected_features, json["features"]
  end

  private

  def expected_features
    {
      "anonymous_access" => Settings.allow_anonymous,
      "api_token_authentication" => true,
      "accounts" => {
        "enabled" => false
      },
      "pushes" => {
        "enabled" => true,
        "email_auto_dispatch" => false,
        "file_attachments" => {
          "enabled" => Settings.enable_file_pushes,
          "requires_authentication" => true
        },
        "url_pushes" => {
          "enabled" => Settings.enable_url_pushes
        },
        "qr_code_pushes" => {
          "enabled" => Settings.enable_qr_pushes
        }
      },
      "requests" => {
        "enabled" => false
      }
    }
  end
end
