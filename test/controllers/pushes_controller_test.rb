# frozen_string_literal: true

require "test_helper"

class PushesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.mail.smtp_address = "smtp.example.com"

    @push = pushes(:test_push)
    @user = @push.user
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
  test "create enqueues SendNotifyByEmailJob when user is signed in and params present" do
    job = assert_enqueued_with(job: SendNotifyByEmailJob) do
      post pushes_path, params: {
        push: {
          kind: "text",
          payload: "secret",
          notify_by_email_recipients: "recipient@example.com",
          notify_by_email_locale: "fr"
        }
      }

      assert_response :redirect
    end

    push_url_token = response.redirect_url.match(/\/p\/(.*)\/preview/)[1]
    push = Push.find_by(url_token: push_url_token)

    notify_by_email = NotifyByEmail.find(job.arguments.first)

    assert_equal "recipient@example.com", notify_by_email.recipients
    assert_equal "fr", notify_by_email.locale
    assert_equal push, notify_by_email.push
  end

  test "create doesn't enqueue SendNotifyByEmailJob when user is not signed in" do
    sign_out @user

    assert_no_enqueued_jobs(only: SendNotifyByEmailJob) do
      post pushes_path, params: {
        push: {
          kind: "text",
          payload: "secret",
          notify_by_email_recipients: "someone@example.com",
          notify_by_email_locale: "fr"
        }
      }

      assert_response :unprocessable_content
      assert_includes response.body, "You need to be signed in to notify by email"
    end
  end

  test "create doesn't enqueue SendNotifyByEmailJob when email service is not configured" do
    Settings.mail.smtp_address = nil

    assert_no_enqueued_jobs(only: SendNotifyByEmailJob) do
      post pushes_path, params: {
        push: {
          kind: "text",
          payload: "secret",
          notify_by_email_recipients: "someone@example.com",
          notify_by_email_locale: "fr"
        }
      }

      assert_response :unprocessable_content
      assert_includes response.body, "Notifying by email is not available"
    end
  end

  test "create doesn't enqueue SendNotifyByEmailJob if any mail is not provided" do
    assert_no_enqueued_jobs(only: SendNotifyByEmailJob) do
      post pushes_path, params: {
        push: {
          kind: "text",
          payload: "secret",
          notify_by_email_recipients: "",
          notify_by_email_locale: "fr"
        }
      }
    end

    assert_response :redirect

    push_url_token = response.redirect_url.match(/\/p\/(.*)\/preview/)[1]
    push = Push.find_by(url_token: push_url_token)

    creation_logs = push.audit_logs.where(kind: :creation)
    assert_equal 1, creation_logs.count

    # creation_email_send log is inside the transaction and should rollback.
    creation_email_send_logs = push.audit_logs.where(kind: :creation_email_send)
    assert_equal 0, creation_email_send_logs.count
  end

  # edit
  test "edit does not show notify_by_email_recipients field when push is edited" do
    get edit_push_path(@push)

    assert_select "input[name=?]", "push[notify_by_email_recipients]", count: 0
  end

  # preview
  test "preview shows notify_by_email_recipients field when user is signed in and email service is configured" do
    get preview_push_path(@push)

    assert_select "input[name=?]", "push[notify_by_email_recipients]", count: 1
  end

  # notify_by_email
  test "notify_by_email enqueues SendNotifyByEmailJob when user is signed in and params present" do
    assert_enqueued_with(job: SendNotifyByEmailJob) do
      post notify_by_email_push_path(@push), params: {
        push: {
          notify_by_email_recipients: "recipient@example.com",
          notify_by_email_locale: "en"
        }
      }
    end
  end

  test "notify_by_email retains form values when validation fails" do
    post notify_by_email_push_path(@push), params: {
      push: {
        notify_by_email_recipients: "invalid-email, another-invalid",
        notify_by_email_locale: "fr"
      }
    }

    assert_response :unprocessable_content
    assert_select "input[name=?][value=?]", "push[notify_by_email_recipients]", "invalid-email, another-invalid"
    assert_select "input[name=?][value=?]", "push[notify_by_email_locale]", "fr"
  end

  test "notify_by_email redirects to preview when user is not signed in and disable_logins is true" do
    Settings.disable_logins = true
    sign_out @user

    post notify_by_email_push_path(@push), params: {
      push: {
        notify_by_email_recipients: "recipient@example.com"
      }
    }

    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "notify_by_email redirects non-owner to root" do
    sign_in users(:luca)

    post notify_by_email_push_path(@push), params: {
      push: {
        notify_by_email_recipients: "recipient@example.com"
      }
    }

    assert_redirected_to root_url
  end

  test "notify_by_email fails with error when user login is disabled" do
    Settings.disable_logins = true

    post notify_by_email_push_path(@push), params: {
      push: {
        notify_by_email_recipients: "recipient@example.com"
      }
    }

    assert_response :unprocessable_content
    assert_includes response.body, "Notifying by email is not available"
  end

  test "notify_by_email redirects to preview when push does not belong to user and disable_logins is false" do
    sign_out @user

    post notify_by_email_push_path(@push), params: {
      push: {
        notify_by_email_recipients: "recipient@example.com"
      }
    }

    assert_response :redirect
    assert_redirected_to new_user_session_path
    assert_nil flash[:notice]
  end
end
