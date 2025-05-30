# frozen_string_literal: true

require "test_helper"

class PasswordJsonPassphraseTest < ActionDispatch::IntegrationTest
  def test_basic_json_passphrase
    post passwords_path(format: :json), params: {password: {payload: "testpw", passphrase: "asdf"}}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("payload") == false # No payload on create response
    assert res.key?("url_token")
    assert res.key?("passphrase")
    assert_equal "asdf", res["passphrase"]

    url_token = res["url_token"]

    # Now try to retrieve the password directly
    # We should get an error because we didn't provide a passphrase
    get "/p/#{url_token}.json"
    assert_response :unauthorized

    res = JSON.parse(@response.body)
    assert res.key?("error")
    assert_equal "That passphrase is incorrect.", res["error"]

    # Now try to retrieve the password with the correct passphrase
    get "/p/#{url_token}.json?passphrase=asdf"
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("expired")
    assert_equal false, res["expired"]
    assert res.key?("deleted")
    assert_equal false, res["deleted"]
    assert res.key?("payload")
    assert_equal "testpw", res["payload"]
  end

  def test_basic_json_bad_passphrase
    post passwords_path(format: :json), params: {password: {payload: "testpw", passphrase: "asdf"}}
    assert_response :success

    res = JSON.parse(@response.body)
    assert_not res.key?("payload")
    assert res.key?("url_token")
    assert res.key?("passphrase")

    url_token = res["url_token"]
    failed_passphrase_log_count = AuditLog.where(kind: :failed_passphrase).count

    # Now try to retrieve the password directly
    # We should get an error because we didn't provide a passphrase
    get "/p/#{url_token}.json"
    assert_response :unauthorized

    res = JSON.parse(@response.body)
    assert res.key?("error")
    assert_equal "That passphrase is incorrect.", res["error"]
    assert_equal failed_passphrase_log_count + 1, AuditLog.where(kind: :failed_passphrase).count

    # Now try to retrieve the password with the correct passphrase
    get "/p/#{url_token}.json?passphrase=badpassphrase"
    assert_response :unauthorized

    res = JSON.parse(@response.body)
    assert res.key?("error")
    assert_equal "That passphrase is incorrect.", res["error"]
    assert_equal failed_passphrase_log_count + 2, AuditLog.where(kind: :failed_passphrase).count
  end
end
