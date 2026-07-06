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
    Rails.application.reload_routes!
  end

  # new
  test "notify_emails_to field is not shown when feature is disabled" do
    Settings.notify_by_email.enabled = false
    Rails.application.reload_routes!

    get new_push_path

    assert_response :success
    assert_select "input[name=?]", "push[notify_emails_to]", count: 0
  end

  test "notify_emails_to field is shown when mail service is configured and user is signed in" do
    get new_push_path

    assert_response :success
    assert_select "input[name=?]", "push[notify_emails_to]", count: 1
  end

  test "notify_emails_to field is not shown when mail service is not configured" do
    Settings.mail.smtp_address = nil

    get new_push_path

    assert_response :success
    assert_select "input[name=?]", "push[notify_emails_to]", count: 0
  end

  test "notify_emails_to fields are not shown when user is not signed in" do
    sign_out @user
    get new_push_path

    assert_response :success
    assert_select "input[name=?]", "push[notify_emails_to]", count: 0
  end

  # create
  test "create enqueues SendNotifyByEmailJob when user is signed in and params present" do
    job = assert_enqueued_with(job: SendNotifyByEmailJob) do
      post pushes_path, params: {
        push: {
          kind: "text",
          payload: "secret",
          notify_emails_to: "recipient@example.com",
          notify_emails_to_locale: "fr"
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
          notify_emails_to: "someone@example.com",
          notify_emails_to_locale: "fr"
        }
      }

      assert_response :unprocessable_content
      assert_includes response.body, "Notify emails to is not allowed for unknown users"
    end
  end

  test "create doesn't enqueue SendNotifyByEmailJob when feature is disabled" do
    Settings.notify_by_email.enabled = false
    Rails.application.reload_routes!

    assert_no_enqueued_jobs(only: SendNotifyByEmailJob) do
      post pushes_path, params: {
        push: {
          kind: "text",
          payload: "secret",
          notify_emails_to: "someone@example.com",
          notify_emails_to_locale: "fr"
        }
      }

      assert_response :unprocessable_content
      assert_includes response.body, "Notify emails to is not available"
      assert_includes response.body, "Notify emails to locale is not available"
      assert_includes response.body, "Notify by email feature is not enabled"
    end
  end

  test "create doesn't enqueue SendNotifyByEmailJob when email service is not configured" do
    Settings.mail.smtp_address = nil

    assert_no_enqueued_jobs(only: SendNotifyByEmailJob) do
      post pushes_path, params: {
        push: {
          kind: "text",
          payload: "secret",
          notify_emails_to: "someone@example.com",
          notify_emails_to_locale: "fr"
        }
      }

      assert_response :unprocessable_content
      assert_includes response.body, "Notify emails to is not available"
      assert_includes response.body, "Notify emails to locale is not available"
    end
  end

  test "create doesn't enqueue SendNotifyByEmailJob if any mail is not provided" do
    assert_no_enqueued_jobs(only: SendNotifyByEmailJob) do
      post pushes_path, params: {
        push: {
          kind: "text",
          payload: "secret",
          notify_emails_to: "",
          notify_emails_to_locale: "fr"
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
  test "edit does not show notify_emails_to field when push is edited" do
    get edit_push_path(@push)

    assert_select "input[name=?]", "push[notify_emails_to]", count: 0
  end

  # preview
  test "preview does not show notify_emails_to when feature is disabled" do
    Settings.notify_by_email.enabled = false
    Rails.application.reload_routes!

    get preview_push_path(@push)

    assert_select "input[name=?]", "push[notify_emails_to]", count: 0
    assert_select "div.collapse#notifyByEmailCollapse", count: 0
  end

  test "preview shows notify_emails_to field when user is signed in and email service is configured" do
    get preview_push_path(@push)

    assert_select "input[name=?]", "push[notify_emails_to]", count: 1
    assert_select "div.collapse#notifyByEmailCollapse.show", count: 0
  end

  # notify_emails
  test "notify_emails returns not found when feature is disabled" do
    Settings.notify_by_email.enabled = false
    Rails.application.reload_routes!

    post "/p/#{@push.url_token}/notify_emails", params: {
      push: {
        notify_emails_to: "recipient@example.com",
        notify_emails_to_locale: "en"
      }
    }

    assert_response :not_found
  end

  test "notify_emails enqueues SendNotifyByEmailJob when user is signed in and params present" do
    assert_enqueued_with(job: SendNotifyByEmailJob) do
      post notify_emails_push_path(@push), params: {
        push: {
          notify_emails_to: "recipient@example.com",
          notify_emails_to_locale: "en"
        }
      }
    end
  end

  test "notify_emails retains form values when validation fails" do
    post notify_emails_push_path(@push), params: {
      push: {
        notify_emails_to: "invalid-email, another-invalid",
        notify_emails_to_locale: "fr"
      }
    }

    assert_response :unprocessable_content
    assert_select "input[name=?][value=?]", "push[notify_emails_to]", "invalid-email, another-invalid"
    assert_select "input[name=?][value=?]", "push[notify_emails_to_locale]", "fr"
    assert_select "div.collapse#notifyByEmailCollapse.show", count: 1
  end

  test "notify_emails redirects to preview when user is not signed in and disable_logins is true" do
    Settings.disable_logins = true
    sign_out @user

    post notify_emails_push_path(@push), params: {
      push: {
        notify_emails_to: "recipient@example.com"
      }
    }

    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "notify_emails redirects non-owner to root" do
    sign_in users(:luca)

    post notify_emails_push_path(@push), params: {
      push: {
        notify_emails_to: "recipient@example.com"
      }
    }

    assert_redirected_to root_url
  end

  test "notify_emails fails with error when user login is disabled" do
    Settings.disable_logins = true

    post notify_emails_push_path(@push), params: {
      push: {
        notify_emails_to: "recipient@example.com"
      }
    }

    assert_response :unprocessable_content
    assert_includes response.body, "Notify emails to is not available"
  end

  test "notify_emails redirects to preview when push does not belong to user and disable_logins is false" do
    sign_out @user

    post notify_emails_push_path(@push), params: {
      push: {
        notify_emails_to: "recipient@example.com"
      }
    }

    assert_response :redirect
    assert_redirected_to new_user_session_path
    assert_nil flash[:notice]
  end

  test "access is rate limited after five attempts per push" do
    @push.update!(passphrase: "secret")

    5.times do |i|
      post access_push_path(@push), params: {passphrase: "wrong#{i}"}
      assert_response :redirect
    end

    post access_push_path(@push), params: {passphrase: "wrong5"}

    assert_response :redirect
    assert_redirected_to passphrase_push_path(@push)
    assert_match(/Too many passphrase attempts/, flash[:alert])
  end

  test "notify_emails is rate limited after five bursts per user" do
    Rails.cache.clear

    5.times do |i|
      post notify_emails_push_path(@push), params: {
        push: {
          notify_emails_to: "recipient#{i}@example.com"
        }
      }
    end

    post notify_emails_push_path(@push), params: {
      push: {
        notify_emails_to: "recipient5@example.com"
      }
    }

    assert_response :redirect
    assert_redirected_to preview_push_path(@push)
    assert_match(/Too many email notification requests/, flash[:alert])
  end
end
