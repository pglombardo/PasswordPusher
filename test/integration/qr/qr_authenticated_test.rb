# frozen_string_literal: true

require "test_helper"

class QrAuthenticatedTest < ActionDispatch::IntegrationTest
  setup do
    Settings.enable_logins = true
    Settings.enable_qr_pushes = true
  end

  def test_authenticated_json_creation
    post json_pushes_path(format: :json),
      params: {password: {kind: "qr", payload: "testpw"}},
      headers: {"Authorization" => "Bearer #{users(:luca).authentication_token}"}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("payload") == false # No payload on create response
  end

  def test_authenticated_json_creation_with_bad_token
    post json_pushes_path(format: :json),
      params: {password: {kind: "qr", payload: "testpw"}},
      headers: {"Authorization" => "Bearer 00000200000000001000000000000000"}
    assert_response :unauthorized
  end
end
