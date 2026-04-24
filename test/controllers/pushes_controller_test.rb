# frozen_string_literal: true

require "test_helper"

class PushesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include Devise::Test::IntegrationHelpers

  setup do
    Rails.application.routes.default_url_options[:host] = "test.host"

    Settings.disable_logins = false
    Settings.enable_url_pushes = true
    Settings.mail.smtp_address = "smtp.example.com"

    @user = users(:giuliana)
    sign_in @user
  end

  teardown do
    Settings.reload!
  end

  # new
  test "notify_by_email_recipients field is shown when mail service is configured and user is signed in" do
    get new_push_path

    assert_response :success
    assert_select "input[name=?]", "push[notify_by_email_recipients]", count: 1
  end

  test "notify_by_email_recipients field is not shown when mail service is not configured" do
    Settings.mail.smtp_address = nil

    get new_push_path

    assert_response :success
    assert_select "input[name=?]", "push[notify_by_email_recipients]", count: 0
  end

  test "notify_by_email_recipients fields are not shown when user is not signed in" do
    sign_out @user
    get new_push_path

    assert_response :success
    assert_select "input[name=?]", "push[notify_by_email_recipients]", count: 0
  end

  # create
  test "create enqueues SendPushCreatedEmailJob when user is  signed in and params present" do
    job = assert_enqueued_with(job: SendPushCreatedEmailJob) do
      post pushes_path, params: {
        push: {
          kind: "text",
          payload: "secret",
          notify_by_email_recipients: "recipient@example.com",
          notify_by_email_locale: "en"
        }
      }

      assert_response :redirect
    end

    push_url_token = response.redirect_url.match(/\/p\/(.*)\/preview/)[1]
    push = Push.find_by(url_token: push_url_token)

    notify_by_email = NotifyByEmail.find(job.arguments.first)

    assert_equal "recipient@example.com", notify_by_email.recipients
    assert_equal "en", notify_by_email.locale
    assert_equal push, notify_by_email.push
  end

  test "create doesn't enqueue SendPushCreatedEmailJob when user is not signed in" do
    sign_out @user

    assert_no_enqueued_jobs(only: SendPushCreatedEmailJob) do
      post pushes_path, params: {
        push: {
          kind: "text",
          payload: "secret",
          notify_by_email_recipients: "someone@example.com",
          notify_by_email_locale: "fr"
        }
      }

      assert_response :redirect
    end
  end

  test "create doesn't enqueue SendPushCreatedEmailJob when email service is not configured" do
    Settings.mail.smtp_address = nil

    assert_no_enqueued_jobs(only: SendPushCreatedEmailJob) do
      post pushes_path, params: {
        push: {
          kind: "text",
          payload: "secret",
          notify_by_email_recipients: "someone@example.com",
          notify_by_email_locale: "fr"
        }
      }

      assert_response :redirect
    end
  end

  # edit
  test "edit does not show notify_by_email_recipients field when push is edited" do
    get edit_push_path(@user.pushes.first)

    assert_select "input[name=?]", "push[notify_by_email_recipients]", count: 0
  end

  # preview
  test "preview shows notify_by_email_recipients field when user is signed in and email service is configured" do
    get preview_push_path(@user.pushes.first)

    assert_select "input[name=?]", "push[notify_by_email_recipients]", count: 1
  end

  # share
  test "notify_by_email enqueues SendPushCreatedEmailJob when user is signed in and params present" do
    assert_enqueued_with(job: SendPushCreatedEmailJob) do
      post notify_by_email_push_path(@user.pushes.first), params: {
        push: {
          notify_by_email_recipients: "recipient@example.com",
          notify_by_email_locale: "en"
        }
      }
    end
  end
end
