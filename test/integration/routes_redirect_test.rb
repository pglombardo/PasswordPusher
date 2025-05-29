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

  test "redirects preserve query parameters" do
    get "/f/abc123?locale=bar&baz=qux"
    # Now we're checking that query parameters are preserved
    follow_redirect!

    # Parse the query string to check parameters independent of order
    path, query = request.fullpath.split("?")
    query_params = Rack::Utils.parse_query(query)

    assert_equal "/p/abc123", path
    assert_equal "bar", query_params["locale"]
    assert_equal "qux", query_params["baz"]
    assert_response :success
  end
end
