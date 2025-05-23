# frozen_string_literal: true

require "test_helper"

class ApiVersionTest < ActionDispatch::IntegrationTest
  def test_anonymous_version_endpoint
    get "/api/v1/version.json"
    assert_response :success
    assert_equal Version.current.to_s, JSON.parse(@response.body)["application_version"]
    assert_equal Apipie.configuration.default_version, JSON.parse(@response.body)["api_version"]
    assert_equal "oss", JSON.parse(@response.body)["edition"]

    get "/api/v1/version"
    assert_response :success
    assert_equal Version.current.to_s, JSON.parse(@response.body)["application_version"]
    assert_equal Apipie.configuration.default_version, JSON.parse(@response.body)["api_version"]
    assert_equal "oss", JSON.parse(@response.body)["edition"]
  end

  def test_authenticated_version_endpoint
    @user_one = users(:one)
    sign_in @user_one

    get "/api/v1/version.json",
      headers: {
        "Accept" => "application/json",
        "Authorization" => "Bearer #{@user_one.authentication_token}"
      }

    assert_response :success
    assert_equal Version.current.to_s, JSON.parse(@response.body)["application_version"]
    assert_equal Apipie.configuration.default_version, JSON.parse(@response.body)["api_version"]
    assert_equal "oss", JSON.parse(@response.body)["edition"]

    @user_one = users(:one)
    sign_in @user_one

    get "/api/v1/version",
      headers: {
        "Accept" => "application/json",
        "Authorization" => "Bearer #{@user_one.authentication_token}"
      }

    assert_response :success
    assert_equal Version.current.to_s, JSON.parse(@response.body)["application_version"]
    assert_equal Apipie.configuration.default_version, JSON.parse(@response.body)["api_version"]
    assert_equal "oss", JSON.parse(@response.body)["edition"]
  end
end
