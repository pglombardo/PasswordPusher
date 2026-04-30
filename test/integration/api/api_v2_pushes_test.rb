# frozen_string_literal: true

require "test_helper"

class ApiV2PushesTest < ActionDispatch::IntegrationTest
  def bearer_headers(user)
    {"Authorization" => "Bearer #{user.authentication_token}"}
  end

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

  def test_show_rejects_invalid_token_header_even_for_public_endpoint
    push = pushes(:test_push)

    get "/api/v2/pushes/#{push.url_token}",
      headers: {"Authorization" => "Bearer invalid-token"},
      as: :json

    assert_response :unauthorized
  end

  def test_preview_rejects_invalid_token_header_even_for_public_endpoint
    push = pushes(:test_push)

    get "/api/v2/pushes/#{push.url_token}/preview",
      headers: {"Authorization" => "Bearer invalid-token"},
      as: :json

    assert_response :unauthorized
  end

  def test_show_requires_passphrase_when_set
    push = pushes(:test_push)
    push.update!(passphrase: "super-secret")

    get "/api/v2/pushes/#{push.url_token}", as: :json

    assert_response :unauthorized
  end

  def test_show_rejects_wrong_passphrase
    push = pushes(:test_push)
    push.update!(passphrase: "super-secret")

    get "/api/v2/pushes/#{push.url_token}",
      params: {passphrase: "wrong-passphrase"},
      as: :json

    assert_response :unauthorized
  end

  def test_show_accepts_valid_passphrase
    push = pushes(:test_push)
    push.update!(passphrase: "super-secret")

    get "/api/v2/pushes/#{push.url_token}",
      params: {passphrase: "super-secret"},
      as: :json

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

  def test_audit_forbidden_for_authenticated_non_owner
    push = pushes(:test_push)
    user = users(:one)

    get "/api/v2/pushes/#{push.url_token}/audit",
      headers: bearer_headers(user),
      as: :json

    assert_response :forbidden
  end

  def test_audit_allowed_for_authenticated_owner
    push = pushes(:test_push)
    owner = users(:giuliana)

    get "/api/v2/pushes/#{push.url_token}/audit",
      headers: bearer_headers(owner),
      as: :json

    assert_response :success
  end

  def test_audit_includes_notify_by_email_details
    push = pushes(:test_push)
    owner = users(:giuliana)

    get "/api/v2/pushes/#{push.url_token}/audit",
      headers: bearer_headers(owner),
      as: :json

    body = JSON.parse(response.body)
    log = body["logs"].select { |view| view["kind"] == "creation_email_send" }.first

    assert_equal "en", log["notify_by_email_locale"]
    assert_equal "one@example.com", log["notify_by_email_recipients"]
    assert_equal "pending", log["notify_by_email_status"]
    assert_nil log["notify_by_email_successful_sends"]
    assert_nil log["notify_by_email_proceed_at"]
  end

  def test_audit_includes_notify_by_email_details_for_completed_notify_by_email
    Rails.application.routes.default_url_options[:host] = "test.host"

    push = pushes(:test_push)
    notify_by_email = notify_by_emails(:one)
    owner = users(:giuliana)

    travel_to Time.zone.local(2026, 1, 1, 1, 0, 0) do
      SendPushCreatedEmailJob.perform_now(notify_by_email.id)
    end
    get "/api/v2/pushes/#{push.url_token}/audit",
      headers: bearer_headers(owner),
      as: :json

    body = JSON.parse(response.body)
    log = body["logs"].find { |log| log["kind"] == "creation_email_send" }

    assert_equal "en", log["notify_by_email_locale"]
    assert_equal "one@example.com", log["notify_by_email_recipients"]
    assert_equal "completed", log["notify_by_email_status"]
    assert_equal "one@example.com", log["notify_by_email_successful_sends"]
    assert_equal "2026-01-01T01:00:00.000Z", log["notify_by_email_proceed_at"]
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

  def test_destroy_forbidden_for_authenticated_non_owner_when_not_deletable_by_viewer
    push = pushes(:test_push)
    push.update!(deletable_by_viewer: false)
    user = users(:one)

    delete "/api/v2/pushes/#{push.url_token}",
      headers: bearer_headers(user),
      as: :json

    assert_response :unauthorized
  end

  def test_destroy_allowed_for_authenticated_owner
    push = pushes(:test_push)
    owner = users(:giuliana)

    delete "/api/v2/pushes/#{push.url_token}",
      headers: bearer_headers(owner),
      as: :json

    assert_response :success
    assert push.reload.expired?
  end

  def test_destroy_allowed_for_anonymous_viewer_when_deletable_by_viewer
    push = pushes(:test_push)
    push.update!(deletable_by_viewer: true)

    delete "/api/v2/pushes/#{push.url_token}", as: :json

    assert_response :success
    assert push.reload.expired?
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

  def test_create_with_missing_payload_returns_json_validation_error_without_accept_header
    post "/api/v2/pushes",
      params: {
        push: {
          expire_after_days: 1,
          expire_after_views: 5
        }
      }.to_json,
      headers: {"Content-Type" => "application/json"}

    assert_response :unprocessable_content
    assert_equal "application/json; charset=utf-8", response.content_type
    body = JSON.parse(response.body)
    assert body.key?("payload")
  end

  def test_create_file_upload_requires_authentication_even_when_allow_anonymous_enabled
    previous_allow_anonymous = Settings.allow_anonymous
    previous_enable_file_pushes = Settings.enable_file_pushes

    Settings.allow_anonymous = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!

    post "/api/v2/pushes",
      params: {
        push: {
          payload: "v2-file-push-without-auth",
          files: [fixture_file_upload("monkey.png", "image/jpeg")]
        }
      }

    assert_response :unauthorized
  ensure
    Settings.allow_anonymous = previous_allow_anonymous
    Settings.enable_file_pushes = previous_enable_file_pushes
    Rails.application.reload_routes!
  end

  def test_create_file_upload_allows_authenticated_user_when_allow_anonymous_enabled
    original_allow_anonymous = Settings.allow_anonymous
    original_enable_file_pushes = Settings.enable_file_pushes
    Settings.allow_anonymous = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!
    user = users(:luca)

    post "/api/v2/pushes",
      params: {
        push: {
          payload: "v2-file-push-with-auth",
          files: [fixture_file_upload("monkey.png", "image/jpeg")]
        }
      },
      headers: bearer_headers(user)

    assert_response :created
    body = JSON.parse(response.body)
    assert body["url_token"].present?
  ensure
    Settings.allow_anonymous = original_allow_anonymous
    Settings.enable_file_pushes = original_enable_file_pushes
    Rails.application.reload_routes!
  end

  def test_create_with_empty_files_key_requires_authentication_even_when_allow_anonymous_enabled
    original_allow_anonymous = Settings.allow_anonymous
    original_enable_file_pushes = Settings.enable_file_pushes
    Settings.allow_anonymous = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!

    post "/api/v2/pushes",
      params: {
        push: {
          payload: "v2-file-key-empty-without-auth",
          files: []
        }
      },
      as: :json

    assert_response :unauthorized
  ensure
    Settings.allow_anonymous = original_allow_anonymous
    Settings.enable_file_pushes = original_enable_file_pushes
    Rails.application.reload_routes!
  end

  def test_create_with_valid_payload_returns_json_created_without_accept_header
    assert_difference("Push.count", 1) do
      post "/api/v2/pushes",
        params: {
          push: {
            payload: "valid-secret-without-accept",
            expire_after_days: 1,
            expire_after_views: 5
          }
        }.to_json,
        headers: {"Content-Type" => "application/json"}
    end

    assert_response :created
    assert_equal "application/json; charset=utf-8", response.content_type
    body = JSON.parse(response.body)
    assert body["url_token"].present?
  end

  def test_create_with_null_payload_returns_json_validation_error_without_accept_header
    post "/api/v2/pushes",
      params: {
        push: {
          payload: nil,
          expire_after_days: 1,
          expire_after_views: 5
        }
      }.to_json,
      headers: {"Content-Type" => "application/json"}

    assert_response :unprocessable_content
    assert_equal "application/json; charset=utf-8", response.content_type
    body = JSON.parse(response.body)
    assert body.key?("payload")
  end

  def test_create_with_missing_push_param_returns_json_bad_request_without_accept_header
    post "/api/v2/pushes",
      params: {}.to_json,
      headers: {"Content-Type" => "application/json"}

    assert_response :bad_request
    assert_equal "application/json; charset=utf-8", response.content_type
    body = JSON.parse(response.body)
    assert body["error"].present?
  end

  def test_create_with_notify_by_email_params_adds_a_job_to_the_queue
    Settings.mail.smtp_address = "smtp.example.com"
    user = users(:one)

    send_email_job = assert_enqueued_with(job: SendPushCreatedEmailJob) do
      post "/api/v2/pushes",
        params: {
          push: {
            payload: "some-secret",
            notify_by_email_recipients: "recipient@example.com",
            notify_by_email_locale: "en"
          }
        },
        headers: bearer_headers(user),
        as: :json

      assert_response :success
    end

    notify_by_email_id = send_email_job.arguments.first
    notify_by_email = NotifyByEmail.find(notify_by_email_id)

    assert_equal "recipient@example.com", notify_by_email.recipients
    assert_equal "en", notify_by_email.locale
  ensure
    Settings.reload!
  end

  def test_create_with_notify_by_email_params_fails_when_email_service_is_not_configured
    Settings.mail.smtp_address = nil
    user = users(:one)

    post "/api/v2/pushes",
      params: {
        push: {
          payload: "some-secret",
          notify_by_email_recipients: "recipient@example.com",
          notify_by_email_locale: "en"
        }
      },
      headers: bearer_headers(user),
      as: :json

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal "Notifying by email is not available.", body["base"][0]
  ensure
    Settings.reload!
  end

  def test_create_with_notify_by_email_params_fails_when_user_is_not_signed_in
    Settings.mail.smtp_address = "smtp.example.com"

    post "/api/v2/pushes",
      params: {
        push: {
          payload: "some-secret",
          notify_by_email_recipients: "recipient@example.com",
          notify_by_email_locale: "en"
        }
      },
      as: :json

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal "You need to be signed in to notify by email for a push.", body["base"][0]
  ensure
    Settings.reload!
  end

  def test_notify_by_email_with_valid_params_returns_json_created
    Settings.mail.smtp_address = "smtp.example.com"
    push = pushes(:test_push)
    owner = push.user

    send_email_job = assert_enqueued_with(job: SendPushCreatedEmailJob) do
      post "/api/v2/pushes/#{push.url_token}/notify_by_email",
        params: {
          recipients: "recipient@example.com",
          locale: "en"
        },
        headers: bearer_headers(owner),
        as: :json

      assert_response :success
    end

    notify_by_email_id = send_email_job.arguments.first
    notify_by_email = NotifyByEmail.find(notify_by_email_id)

    assert_equal "recipient@example.com", notify_by_email.recipients
    assert_equal "en", notify_by_email.locale
    assert_equal push, notify_by_email.push
  ensure
    Settings.reload!
  end

  def test_notify_by_email_with_valid_params_returns_error_when_email_service_is_not_configured
    push = pushes(:test_push)
    owner = push.user

    post "/api/v2/pushes/#{push.url_token}/notify_by_email",
      params: {
        recipients: "recipient@example.com",
        locale: "en"
      },
      headers: bearer_headers(owner),
      as: :json

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)
    assert_equal "Notifying by email is not available.", body["base"][0]
  ensure
    Settings.reload!
  end
end
