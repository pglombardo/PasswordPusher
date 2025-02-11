# frozen_string_literal: true

require "test_helper"

class PasswordAuthenticatedTest < ActionDispatch::IntegrationTest
  def test_authenticated_json_creation
    post passwords_path(format: :json),
      params: {password: {payload: "testpw"}},
      headers: {"Authorization" => "Bearer #{users(:luca).authentication_token}"}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("payload") == false # No payload on create response
  end

  def test_authenticated_json_creation_with_bad_token
    post passwords_path(format: :json),
      params: {password: {payload: "testpw"}},
      headers: {"Authorization" => "Bearer 00000200000000001000000000000000"}
    assert_response :unauthorized
  end
end
