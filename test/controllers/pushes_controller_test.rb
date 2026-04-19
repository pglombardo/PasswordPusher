# frozen_string_literal: true

require "test_helper"

class PushesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include Devise::Test::IntegrationHelpers

  setup do
    Rails.application.routes.default_url_options[:host] = "test.host"
    @default_disable_logins = Settings.disable_logins
    @default_enable_url_pushes = Settings.enable_url_pushes
    @default_mail_service_configured = Settings.mail.smtp_address.present?

    Settings.disable_logins = false
    Settings.enable_url_pushes = true
    Settings.mail.smtp_address = "smtp.example.com"

    @user = users(:giuliana)
    sign_in @user
  end

  teardown do
    Settings.disable_logins = @default_disable_logins
    Settings.enable_url_pushes = @default_enable_url_pushes
    Settings.mail.smtp_address = @default_mail_service_configured
  end

  # new
  test "share_recipients field is shown when mail service is configured and user is signed in" do
    get new_push_path

    assert_response :success
    assert_select "input[name=?]", "push[share_recipients]", count: 1
  end

  test "share_recipients field is not shown when mail service is not configured" do
    Settings.mail.smtp_address = nil

    get new_push_path

    assert_response :success
    assert_select "input[name=?]", "push[share_recipients]", count: 0
  end

  test "share_recipients fields are not shown when user is not signed in" do
    sign_out @user
    get new_push_path

    assert_response :success
    assert_select "input[name=?]", "push[share_recipients]", count: 0
  end

  # create
  test "create fails to set share_recipients and share_locale when user is not signed in" do
    sign_out @user
    post pushes_path, params: {
      push: {
        kind: "text",
        payload: "secret",
        share_recipients: "someone@example.com",
        share_locale: "fr"
      }
    }
    assert_response :unprocessable_content

    assert_includes(response.body, "Share recipients cannot be set if owner is not known")
    assert_includes(response.body, "Share locale cannot be set if owner is not known")
  end

  # create action: signed-in users get share fields from params
  test "create assigns share_recipients and share_locale when signed in and params present" do
    post pushes_path, params: {
      push: {
        kind: "text",
        payload: "secret",
        share_recipients: "recipient@example.com",
        share_locale: "en"
      }
    }

    assert_response :redirect

    push_url_token = response.redirect_url.match(/\/p\/(.*)\/preview/)[1]
    push = Push.find_by(url_token: push_url_token)

    assert_equal "recipient@example.com", push.share_recipients
    assert_equal "en", push.share_locale
  end

  # create action: send_creation_emails is triggered on successful save
  test "create enqueues SendPushCreatedEmailJob on success when signed in and share_recipients present" do
    assert_enqueued_with(job: SendPushCreatedEmailJob) do
      post pushes_path, params: {
        push: {
          kind: "text",
          payload: "secret",
          share_recipients: "a@example.com"
        }
      }
    end
    assert_response :redirect
  end

  # push_params: share fields are permitted for text and url kinds
  test "push_params permits share_recipients and share_locale for text push" do
    post pushes_path, params: {
      push: {
        kind: "text",
        payload: "secret",
        share_recipients: "text@example.com",
        share_locale: "de"
      }
    }
    assert_response :redirect

    push_url_token = response.redirect_url.match(/\/p\/(.*)\/preview/)[1]
    push = Push.find_by(url_token: push_url_token)

    assert_equal "text@example.com", push.share_recipients
    assert_equal "de", push.share_locale
  end

  test "push_params permits share_recipients and share_locale for url push" do
    post pushes_path, params: {
      push: {
        kind: "url",
        payload: "https://example.com",
        share_recipients: "url@example.com",
        share_locale: "es"
      }
    }

    assert_response :redirect

    push_url_token = response.redirect_url.match(/\/p\/(.*)\/preview/)[1]
    push = Push.find_by(url_token: push_url_token)

    assert_equal "url@example.com", push.share_recipients
    assert_equal "es", push.share_locale
  end

  # edit
  test "edit does not show share_recipients field when push is edited" do
    get edit_push_path(@user.pushes.first)

    assert_select "input[name=?]", "push[share_recipients]", count: 0
  end

  # update
  test "update ignores `share_recipients` and `share_locale` when they are updated" do
    push = pushes(:test_push)
    push.update(user: @user)
    patch push_path(push), params: {
      push: {
        share_recipients: "someone@example.com",
        share_locale: "fr"
      }
    }

    assert_response :found
    assert_equal push.share_recipients, "one@example.com, two@example.com"
    assert_equal push.share_locale, ""
  end
end
