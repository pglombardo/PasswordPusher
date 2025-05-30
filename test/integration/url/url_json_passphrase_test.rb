# frozen_string_literal: true

require "test_helper"

class UrlJsonPassphraseTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_url_pushes = true
    Rails.application.reload_routes!

    @luca = users(:luca)
    @luca.confirm
  end

  def test_basic_json_passphrase
    post urls_path(format: :json), params: {url: {payload: "https://the0x00.dev", passphrase: "asdf"}},
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}

    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("payload") == false # No payload on create response
    assert res.key?("url_token")
    assert res.key?("passphrase")
    assert_equal "asdf", res["passphrase"]

    url_token = res["url_token"]

    # Now try to retrieve the url directly
    # We should get an error because we didn't provide a passphrase
    get "/p/#{url_token}.json"
    assert_response :unauthorized

    res = JSON.parse(@response.body)
    assert res.key?("error")
    assert_equal "That passphrase is incorrect.", res["error"]

    # Now try to retrieve the url with the correct passphrase
    get "/p/#{url_token}.json?passphrase=asdf"
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("expired")
    assert_equal false, res["expired"]
    assert res.key?("deleted")
    assert_equal false, res["deleted"]
    assert res.key?("payload")
    assert_equal "https://the0x00.dev", res["payload"]
  end

  def test_basic_json_bad_passphrase
    post urls_path(format: :json), params: {url: {payload: "https://the0x00.dev", passphrase: "asdf"}},
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}

    assert_response :success

    res = JSON.parse(@response.body)
    assert_not res.key?("payload")
    assert res.key?("url_token")
    assert res.key?("passphrase")

    url_token = res["url_token"]
    failed_passphrase_log_count = AuditLog.where(kind: :failed_passphrase).count

    # Now try to retrieve the url directly
    # We should get an error because we didn't provide a passphrase
    get "/p/#{url_token}.json"
    assert_response :unauthorized

    res = JSON.parse(@response.body)
    assert res.key?("error")
    assert_equal "That passphrase is incorrect.", res["error"]
    assert_equal failed_passphrase_log_count + 1, AuditLog.where(kind: :failed_passphrase).count

    # Now try to retrieve the url with the correct passphrase
    get "/p/#{url_token}.json?passphrase=badpassphrase"
    assert_response :unauthorized

    res = JSON.parse(@response.body)
    assert res.key?("error")
    assert_equal "That passphrase is incorrect.", res["error"]
    assert_equal failed_passphrase_log_count + 2, AuditLog.where(kind: :failed_passphrase).count
  end
end
