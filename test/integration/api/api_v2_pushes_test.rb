# frozen_string_literal: true

require "test_helper"

class ApiV2PushesTest < ActionDispatch::IntegrationTest
  def test_help_api_page_is_available
    get "/help/api"
    assert_response :success
  end

  def test_existing_apipie_docs_remain_available
    get "/api"
    assert_response :success
  end

  def test_versioned_requests_and_accounts_endpoints_are_not_exposed
    get "/api/v2/requests"
    assert_response :not_found

    get "/api/v2/accounts"
    assert_response :not_found
  end

  def test_create_push_with_v2_payload
    assert_difference("Push.count", 1) do
      post "/api/v2/pushes",
        params: {
          push: {
            payload: "api-v2-secret",
            expire_after_days: 1,
            expire_after_views: 3
          }
        },
        as: :json
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert body["url_token"].present?
  end

  def test_show_push_is_public_when_token_is_valid
    push = pushes(:test_push)

    get "/api/v2/pushes/#{push.url_token}", as: :json

    assert_response :success
  end

  def test_active_requires_authentication
    get "/api/v2/pushes/active", as: :json
    assert_response :unauthorized
  end

  def test_expired_requires_authentication
    get "/api/v2/pushes/expired", as: :json
    assert_response :unauthorized
  end

  def test_audit_requires_authentication
    push = pushes(:test_push)

    get "/api/v2/pushes/#{push.url_token}/audit", as: :json
    assert_response :unauthorized
  end

  def test_active_allows_authenticated_access
    user = users(:one)

    get "/api/v2/pushes/active",
      headers: {
        "Authorization" => "Bearer #{user.authentication_token}"
      },
      as: :json

    assert_response :success
  end

  def test_create_requires_auth_when_allow_anonymous_disabled
    Settings.allow_anonymous = false

    post "/api/v2/pushes",
      params: {
        push: {
          payload: "blocked-anon-create"
        }
      },
      as: :json

    assert_includes [401, 302], response.status
  ensure
    Settings.allow_anonymous = true
  end
end
