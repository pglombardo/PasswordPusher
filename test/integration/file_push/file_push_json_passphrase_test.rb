# frozen_string_literal: true

require "test_helper"

class FilePushJsonPassphraseTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!
    @luca = users(:luca)
    @luca.confirm
  end

  def test_basic_json_passphrase
    post file_pushes_path(format: :json), params: {
                                            file_push: {
                                              payload: "Message",
                                              passphrase: "asdf",
                                              files: [
                                                fixture_file_upload("monkey.png", "image/jpeg")
                                              ]
                                            }
                                          },
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("payload") == false # No payload on create response
    assert res.key?("url_token")
    assert_not res.key?("passphrase")

    url_token = res["url_token"]

    # Now try to retrieve the file push directly
    # We should get an error because we didn't provide a passphrase
    get "/f/#{url_token}.json"
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("error")
    assert_equal "This push has a passphrase that was incorrect or not provided.", res["error"]

    # Now try to retrieve the password with the correct passphrase
    get "/f/#{url_token}.json?passphrase=asdf"
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("expired")
    assert_equal false, res["expired"]
    assert res.key?("deleted")
    assert_equal false, res["deleted"]
    assert res.key?("payload")
    assert_equal "Message", res["payload"]
  end

  def test_basic_json_bad_passphrase
    post file_pushes_path(format: :json), params: {
                                            file_push: {
                                              payload: "testpw",
                                              passphrase: "asdf",
                                              files: [
                                                fixture_file_upload("monkey.png", "image/jpeg")
                                              ]
                                            }
                                          },
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("payload") == false # No payload on create response
    assert res.key?("url_token")
    assert_not res.key?("passphrase")

    url_token = res["url_token"]

    # Now try to retrieve the file push directly
    # We should get an error because we didn't provide a passphrase
    get "/f/#{url_token}.json"
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("error")
    assert_equal "This push has a passphrase that was incorrect or not provided.", res["error"]

    # Now try to retrieve the password with the incorrect passphrase
    get "/f/#{url_token}.json?passphrase=badpassphrase"
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("error")
    assert_equal "This push has a passphrase that was incorrect or not provided.", res["error"]
  end
end
