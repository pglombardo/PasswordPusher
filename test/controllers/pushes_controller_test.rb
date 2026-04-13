# frozen_string_literal: true

require "test_helper"

class PushesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include Devise::Test::IntegrationHelpers

  setup do
    Rails.application.routes.default_url_options[:host] = "test.host"
    @default_disable_logins = Settings.disable_logins
    @default_enable_url_pushes = Settings.enable_url_pushes
    @default_enable_user_account_emails = Settings.enable_user_account_emails
    Settings.disable_logins = false
    Settings.enable_url_pushes = true
    Settings.enable_user_account_emails = true
    @user = users(:luca)
  end

  teardown do
    Settings.disable_logins = @default_disable_logins
    Settings.enable_url_pushes = @default_enable_url_pushes
    Settings.enable_user_account_emails = @default_enable_user_account_emails
  end

  # create action: anonymous users must not get notify fields set
  test "create fails to set notify_emails_to and notify_emails_to_locale when user is not signed in" do
    post pushes_path, params: {
      push: {
        kind: "text",
        payload: "secret",
        notify_emails_to: "someone@example.com",
        notify_emails_to_locale: "fr"
      }
    }
    assert_response :unprocessable_content

    assert_includes(response.body, "Notify emails to cannot be set if owner is not known")
    assert_includes(response.body, "Notify emails to locale cannot be set if owner is not known")
  end

  # create action: signed-in users get notify fields from params
  test "create assigns notify_emails_to and notify_emails_to_locale when signed in and params present" do
    sign_in @user
    post pushes_path, params: {
      push: {
        kind: "text",
        payload: "secret",
        notify_emails_to: "recipient@example.com",
        notify_emails_to_locale: "en"
      }
    }

    assert_response :redirect

    push_url_token = response.redirect_url.match(/\/p\/(.*)\/preview/)[1]
    push = Push.find_by(url_token: push_url_token)

    assert_equal "recipient@example.com", push.notify_emails_to
    assert_equal "en", push.notify_emails_to_locale
  end

  # create action: send_creation_emails is triggered on successful save
  test "create enqueues SendPushCreatedEmailJob on success when signed in and notify_emails_to present" do
    sign_in @user
    assert_enqueued_with(job: SendPushCreatedEmailJob) do
      post pushes_path, params: {
        push: {
          kind: "text",
          payload: "secret",
          notify_emails_to: "a@example.com"
        }
      }
    end
    assert_response :redirect
  end

  # push_params: notify fields are permitted for text and url kinds
  test "push_params permits notify_emails_to and notify_emails_to_locale for text push" do
    sign_in @user
    post pushes_path, params: {
      push: {
        kind: "text",
        payload: "secret",
        notify_emails_to: "text@example.com",
        notify_emails_to_locale: "de"
      }
    }
    assert_response :redirect

    push_url_token = response.redirect_url.match(/\/p\/(.*)\/preview/)[1]
    push = Push.find_by(url_token: push_url_token)

    assert_equal "text@example.com", push.notify_emails_to
    assert_equal "de", push.notify_emails_to_locale
  end

  test "push_params permits notify_emails_to and notify_emails_to_locale for url push" do
    sign_in @user
    post pushes_path, params: {
      push: {
        kind: "url",
        payload: "https://example.com",
        notify_emails_to: "url@example.com",
        notify_emails_to_locale: "es"
      }
    }

    assert_response :redirect

    push_url_token = response.redirect_url.match(/\/p\/(.*)\/preview/)[1]
    push = Push.find_by(url_token: push_url_token)

    assert_equal "url@example.com", push.notify_emails_to
    assert_equal "es", push.notify_emails_to_locale
  end
end
