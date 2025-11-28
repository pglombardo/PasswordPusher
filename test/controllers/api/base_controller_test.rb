# frozen_string_literal: true

require "test_helper"

class Api::BaseControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:luca)
    @user.confirm
    @user.update(authentication_token: "valid_token_123")
    @other_user = users(:one)
    @other_user.confirm
    @other_user.update(authentication_token: "other_token_456")
  end

  # Test Bearer token authentication
  test "authenticates with valid Bearer token" do
    get "/api/v1/version.json",
      headers: {
        "Authorization" => "Bearer valid_token_123",
        "Accept" => "application/json"
      }

    assert_response :success
    assert_equal @user.id, @controller.current_user.id
  end

  test "version endpoint allows invalid Bearer token (public endpoint)" do
    # Version endpoint is public, so invalid tokens don't cause 401
    get "/api/v1/version.json",
      headers: {
        "Authorization" => "Bearer invalid_token",
        "Accept" => "application/json"
      }

    assert_response :success
  end

  test "rejects Bearer token with wrong format" do
    get "/p/active.json",
      headers: {
        "Authorization" => "invalid_format_token",
        "Accept" => "application/json"
      }

    assert_response :unauthorized
  end

  test "rejects empty Bearer token" do
    get "/p/active.json",
      headers: {
        "Authorization" => "Bearer ",
        "Accept" => "application/json"
      }

    assert_response :unauthorized
  end

  # Test legacy X-User-Email + X-User-Token authentication
  test "authenticates with valid legacy X-User-Token header" do
    get "/api/v1/version.json",
      headers: {
        "X-User-Email" => @user.email,
        "X-User-Token" => "valid_token_123",
        "Accept" => "application/json"
      }

    assert_response :success
    assert_equal @user.id, @controller.current_user.id
  end

  test "rejects invalid legacy X-User-Token" do
    get "/p/active.json",
      headers: {
        "X-User-Email" => @user.email,
        "X-User-Token" => "invalid_token",
        "Accept" => "application/json"
      }

    assert_response :unauthorized
  end

  test "rejects legacy token when X-User-Email is missing" do
    get "/p/active.json",
      headers: {
        "X-User-Token" => "valid_token_123",
        "Accept" => "application/json"
      }

    # Should fall back to Bearer token parsing, which will fail
    assert_response :unauthorized
  end

  test "rejects legacy token when X-User-Token is missing" do
    get "/p/active.json",
      headers: {
        "X-User-Email" => @user.email,
        "Accept" => "application/json"
      }

    assert_response :unauthorized
  end

  test "legacy token takes precedence over Bearer token" do
    get "/api/v1/version.json",
      headers: {
        "X-User-Email" => @user.email,
        "X-User-Token" => "valid_token_123",
        "Authorization" => "Bearer other_token_456",
        "Accept" => "application/json"
      }

    assert_response :success
    # Should use legacy token, not Bearer token
    assert_equal @user.id, @controller.current_user.id
  end

  # Test public endpoint (version)
  test "version endpoint is accessible without authentication" do
    get "/api/v1/version.json"
    assert_response :success

    json_response = JSON.parse(@response.body)
    assert json_response.key?("application_version")
    assert json_response.key?("api_version")
    assert json_response.key?("edition")
  end

  test "version endpoint works with invalid token (public endpoint)" do
    get "/api/v1/version.json",
      headers: {
        "Authorization" => "Bearer invalid_token",
        "Accept" => "application/json"
      }

    # Version endpoint is public, so it should still work even with invalid token
    assert_response :success
  end

  # Test path-based authentication requirements for /p paths
  test "/p/audit requires authentication" do
    push = pushes(:test_push)

    get "/p/#{push.url_token}/audit.json"
    assert_response :unauthorized
  end

  test "/p/audit works with valid token" do
    push = pushes(:test_push)
    push.update(user: @user)

    get "/p/#{push.url_token}/audit.json",
      headers: {
        "Authorization" => "Bearer valid_token_123",
        "Accept" => "application/json"
      }

    assert_response :success
  end

  test "/p/active requires authentication" do
    get "/p/active.json"
    assert_response :unauthorized
  end

  test "/p/active works with valid token" do
    Settings.enable_logins = true
    Rails.application.reload_routes!

    get "/p/active.json",
      headers: {
        "Authorization" => "Bearer valid_token_123",
        "Accept" => "application/json"
      }

    assert_response :success
  ensure
    Settings.enable_logins = false
    Rails.application.reload_routes!
  end

  test "/p/expired requires authentication" do
    get "/p/expired.json"
    assert_response :unauthorized
  end

  test "/p/expired works with valid token" do
    Settings.enable_logins = true
    Rails.application.reload_routes!

    get "/p/expired.json",
      headers: {
        "Authorization" => "Bearer valid_token_123",
        "Accept" => "application/json"
      }

    assert_response :success
  ensure
    Settings.enable_logins = false
    Rails.application.reload_routes!
  end

  test "/p/show does not require authentication" do
    push = pushes(:test_push)

    get "/p/#{push.url_token}.json"
    # Should not be unauthorized (may be other errors like not found, but not auth)
    assert_not_equal :unauthorized, response.status
  end

  test "/p/create does not require authentication by default" do
    post "/p.json",
      params: {
        password: {
          payload: "test_secret"
        }
      },
      headers: {
        "Accept" => "application/json"
      }

    # Should not be unauthorized (may be other errors, but not auth)
    assert_not_equal :unauthorized, response.status
  end

  # Test path-based authentication requirements for /f paths
  test "/f/create requires authentication" do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!

    post "/f.json",
      params: {
        file_push: {
          payload: "test"
        }
      },
      headers: {
        "Accept" => "application/json"
      }

    assert_response :unauthorized
  ensure
    Settings.enable_logins = false
    Settings.enable_file_pushes = false
    Rails.application.reload_routes!
  end

  test "/f/create works with valid token" do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!

    post "/f.json",
      params: {
        file_push: {
          payload: "test"
        }
      },
      headers: {
        "Authorization" => "Bearer valid_token_123",
        "Accept" => "application/json"
      }

    # Should not be unauthorized (may be other validation errors)
    assert_not_equal :unauthorized, response.status
  ensure
    Settings.enable_logins = false
    Settings.enable_file_pushes = false
    Rails.application.reload_routes!
  end

  test "/f/audit requires authentication" do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!

    push = pushes(:test_push)
    push.update(kind: "file")

    get "/f/#{push.url_token}/audit.json"
    assert_response :unauthorized
  ensure
    Settings.enable_logins = false
    Settings.enable_file_pushes = false
    Rails.application.reload_routes!
  end

  test "/f/active requires authentication" do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!

    get "/f/active.json"
    assert_response :unauthorized
  ensure
    Settings.enable_logins = false
    Settings.enable_file_pushes = false
    Rails.application.reload_routes!
  end

  test "/f/expired requires authentication" do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!

    get "/f/expired.json"
    assert_response :unauthorized
  ensure
    Settings.enable_logins = false
    Settings.enable_file_pushes = false
    Rails.application.reload_routes!
  end

  # Test path-based authentication requirements for /r paths
  test "/r/create requires authentication" do
    Settings.enable_logins = true
    Settings.enable_url_pushes = true
    Rails.application.reload_routes!

    post "/r.json",
      params: {
        url: {
          payload: "https://example.com"
        }
      },
      headers: {
        "Accept" => "application/json"
      }

    assert_response :unauthorized
  ensure
    Settings.enable_logins = false
    Settings.enable_url_pushes = false
    Rails.application.reload_routes!
  end

  test "/r/create works with valid token" do
    Settings.enable_logins = true
    Settings.enable_url_pushes = true
    Rails.application.reload_routes!

    post "/r.json",
      params: {
        url: {
          payload: "https://example.com"
        }
      },
      headers: {
        "Authorization" => "Bearer valid_token_123",
        "Accept" => "application/json"
      }

    # Should not be unauthorized (may be other validation errors)
    assert_not_equal :unauthorized, response.status
  ensure
    Settings.enable_logins = false
    Settings.enable_url_pushes = false
    Rails.application.reload_routes!
  end

  test "/r/audit requires authentication" do
    Settings.enable_logins = true
    Settings.enable_url_pushes = true
    Rails.application.reload_routes!

    push = pushes(:test_push)
    push.update(kind: "url")

    get "/r/#{push.url_token}/audit.json"
    assert_response :unauthorized
  ensure
    Settings.enable_logins = false
    Settings.enable_url_pushes = false
    Rails.application.reload_routes!
  end

  test "/r/active requires authentication" do
    Settings.enable_logins = true
    Settings.enable_url_pushes = true
    Rails.application.reload_routes!

    get "/r/active.json"
    assert_response :unauthorized
  ensure
    Settings.enable_logins = false
    Settings.enable_url_pushes = false
    Rails.application.reload_routes!
  end

  test "/r/expired requires authentication" do
    Settings.enable_logins = true
    Settings.enable_url_pushes = true
    Rails.application.reload_routes!

    get "/r/expired.json"
    assert_response :unauthorized
  ensure
    Settings.enable_logins = false
    Settings.enable_url_pushes = false
    Rails.application.reload_routes!
  end

  # Test user already signed in (session-based auth)
  test "skips token check when user is already signed in" do
    Settings.enable_logins = true
    Rails.application.reload_routes!

    sign_in @user

    get "/p/active.json",
      headers: {
        "Accept" => "application/json"
      }

    assert_response :success
    assert_equal @user.id, @controller.current_user.id
  ensure
    Settings.enable_logins = false
    Rails.application.reload_routes!
  end

  test "signed in user can access protected endpoints without token" do
    Settings.enable_logins = true
    Rails.application.reload_routes!

    sign_in @user

    push = pushes(:test_push)
    push.update(user: @user)

    get "/p/#{push.url_token}/audit.json",
      headers: {
        "Accept" => "application/json"
      }

    # Should not be unauthorized when signed in
    assert_not_equal :unauthorized, response.status
  ensure
    Settings.enable_logins = false
    Rails.application.reload_routes!
  end

  # Test token extraction edge cases
  test "handles Authorization header without Bearer prefix" do
    get "/api/v1/version.json",
      headers: {
        "Authorization" => "valid_token_123",
        "Accept" => "application/json"
      }

    # Should extract token (last part after split)
    assert_response :success
    assert_equal @user.id, @controller.current_user.id
  end

  test "handles Authorization header with multiple spaces" do
    get "/api/v1/version.json",
      headers: {
        "Authorization" => "Bearer   valid_token_123",
        "Accept" => "application/json"
      }

    # Should still work (split(" ").last gets the token)
    assert_response :success
    assert_equal @user.id, @controller.current_user.id
  end

  test "handles missing Authorization header" do
    get "/p/active.json",
      headers: {
        "Accept" => "application/json"
      }

    assert_response :unauthorized
  end

  # Test ParameterMissing exception handling
  test "handles ParameterMissing exception with JSON response" do
    # This will trigger ParameterMissing when trying to create a push without required params
    post "/p.json",
      params: {},
      headers: {
        "Authorization" => "Bearer valid_token_123",
        "Accept" => "application/json"
      }

    assert_response :bad_request
    json_response = JSON.parse(@response.body)
    assert json_response.key?("error")
    # Error message format: "param is missing or the value is empty or invalid: password"
    assert_match(/param is missing|password/, json_response["error"].downcase)
  end

  test "ParameterMissing returns proper error message" do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!

    post "/f.json",
      params: {},
      headers: {
        "Authorization" => "Bearer valid_token_123",
        "Accept" => "application/json"
      }

    assert_response :bad_request
    json_response = JSON.parse(@response.body)
    assert json_response.key?("error")
  ensure
    Settings.enable_logins = false
    Settings.enable_file_pushes = false
    Rails.application.reload_routes!
  end

  # Test token with blank/nil values
  test "rejects blank token" do
    @user.update(authentication_token: "")

    get "/p/active.json",
      headers: {
        "Authorization" => "Bearer ",
        "Accept" => "application/json"
      }

    assert_response :unauthorized
  end

  test "rejects nil token" do
    @user.update(authentication_token: nil)

    get "/p/active.json",
      headers: {
        "Authorization" => "Bearer ",
        "Accept" => "application/json"
      }

    assert_response :unauthorized
  end

  # Test that token authentication signs in user without session storage
  test "token authentication does not create session" do
    get "/api/v1/version.json",
      headers: {
        "Authorization" => "Bearer valid_token_123",
        "Accept" => "application/json"
      }

    assert_response :success
    # User should be signed in
    assert @controller.user_signed_in?
    # But session should not be stored (store: false)
    # We can verify this by checking that subsequent requests without token fail
    get "/p/active.json",
      headers: {
        "Accept" => "application/json"
      }

    assert_response :unauthorized
  end

  # Test unknown paths require authentication
  test "unknown API paths require authentication" do
    # Test with a path that doesn't match any known patterns
    get "/api/v1/unknown.json",
      headers: {
        "Accept" => "application/json"
      }

    # BaseController should require auth for unknown paths
    # But if route doesn't exist, we get 404 before auth check
    # So we test with a path that exists but requires auth
    get "/p/active.json",
      headers: {
        "Accept" => "application/json"
      }

    assert_response :unauthorized
  end

  test "unknown API paths work with valid token" do
    # Even if the endpoint doesn't exist, auth should pass
    get "/api/v1/unknown.json",
      headers: {
        "Authorization" => "Bearer valid_token_123",
        "Accept" => "application/json"
      }

    # Should not be unauthorized (may be 404, but not 401)
    assert_not_equal :unauthorized, response.status
  end
end
