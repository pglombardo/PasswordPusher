# frozen_string_literal: true

require "test_helper"

class RoutesRedirectTest < ActionDispatch::IntegrationTest
  test "redirects from /f/:url_token to /p/:url_token" do
    get "/f/abc123"
    assert_redirected_to "/p/abc123"
    assert_response :redirect
    assert_equal 301, response.status
  end

  test "redirects from /f/:url_token/r to /p/:url_token/r" do
    get "/f/abc123/r"
    assert_redirected_to "/p/abc123/r"
    assert_response :redirect
    assert_equal 301, response.status
  end

  test "redirects from /f/:url_token/passphrase to /p/:url_token/passphrase" do
    get "/f/abc123/passphrase"
    assert_redirected_to "/p/abc123/passphrase"
    assert_response :redirect
    assert_equal 301, response.status
  end

  test "redirects from /r/:url_token to /p/:url_token" do
    get "/r/abc123"
    assert_redirected_to "/p/abc123"
    assert_response :redirect
    assert_equal 301, response.status
  end

  test "redirects from /r/:url_token/r to /p/:url_token/r" do
    get "/r/abc123/r"
    assert_redirected_to "/p/abc123/r"
    assert_response :redirect
    assert_equal 301, response.status
  end

  test "redirects from /r/:url_token/passphrase to /p/:url_token/passphrase" do
    get "/r/abc123/passphrase"
    assert_redirected_to "/p/abc123/passphrase"
    assert_response :redirect
    assert_equal 301, response.status
  end

  test "redirects with safe url_token" do
    token = SecureRandom.urlsafe_base64(rand(8..14))
    get "/f/#{token}"
    assert_redirected_to "/p/#{token}"
    assert_response :redirect
    assert_equal 301, response.status
  end

  test "redirects not preserve query parameters" do
    get "/f/abc123?locale=bar&baz=qux"
    # The redirect doesn't automatically preserve query params in the assertion
    # It only redirects the path portion
    assert_redirected_to "/p/abc123?"
    assert_response :redirect
    assert_equal 301, response.status
  end
end
