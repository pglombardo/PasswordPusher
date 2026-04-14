# frozen_string_literal: true

require "test_helper"

class ApiV2VersionTest < ActionDispatch::IntegrationTest
  def test_anonymous_version_endpoint
    get "/api/v2/version"
    assert_response :success

    json = JSON.parse(@response.body)
    assert_equal Version.current.to_s, json["application_version"]
    assert_equal "2.0", json["api_version"]
    assert_equal "oss", json["edition"]
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
    assert_equal "2.0", json["api_version"]
    assert_equal "oss", json["edition"]
  end
end
