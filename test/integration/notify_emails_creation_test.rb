# frozen_string_literal: true

require "test_helper"

class NotifyEmailsCreationTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include Devise::Test::IntegrationHelpers

  setup do
    Rails.application.routes.default_url_options[:host] = "test.host"
    Settings.enable_logins = true
    @user = users(:luca)
  end

  teardown do
    Settings.enable_logins = false
  end

  test "creating push with notify_emails_to enqueues SendPushCreatedEmailJob when logged in" do
    sign_in @user
    assert_enqueued_with(job: SendPushCreatedEmailJob) do
      post pushes_path, params: {
        push: {
          kind: "text",
          payload: "secret",
          notify_emails_to: "recipient@example.com"
        }
      }
    end
    assert_response :redirect
    follow_redirect!
    assert_response :success
  end

  test "creating push with notify_emails_to sends email when jobs performed and user logged in" do
    sign_in @user
    assert_emails 1 do
      perform_enqueued_jobs do
        post pushes_path, params: {
          push: {
            kind: "text",
            payload: "secret",
            notify_emails_to: "recipient@example.com"
          }
        }
      end
    end
    mail = ActionMailer::Base.deliveries.last
    assert_equal ["recipient@example.com"], mail.to
    push = Push.last
    assert_includes mail.body.encoded, push.url_token
  end

  test "creating push without notify_emails_to does not enqueue job" do
    assert_no_enqueued_jobs(only: SendPushCreatedEmailJob) do
      post pushes_path, params: {
        push: {
          kind: "text",
          payload: "secret"
        }
      }
    end
    assert_response :redirect
  end

  test "creating push with invalid notify_emails_to does not create push when logged in" do
    sign_in @user
    assert_no_difference("Push.count") do
      post pushes_path, params: {
        push: {
          kind: "text",
          payload: "secret",
          notify_emails_to: "not-an-email"
        }
      }
    end
    assert_response :unprocessable_content
  end

  test "anonymous user creating push with notify_emails_to in params does not enqueue job" do
    assert_no_enqueued_jobs(only: SendPushCreatedEmailJob) do
      post pushes_path, params: {
        push: {
          kind: "text",
          payload: "secret",
          notify_emails_to: "recipient@example.com"
        }
      }
    end
    assert_response :redirect
    push = Push.last
    assert push.notify_emails_to.blank?, "notify_emails_to should be cleared for anonymous"
  end

  test "push creation form does not show notify emails field when not logged in" do
    get new_push_path(tab: "text")
    assert_response :success
    assert_select "input[name=?]", "push[notify_emails_to]", count: 0
    assert_no_match(/Email notification recipients/i, response.body)
  end

  test "push creation form does not show notify emails field when SMTP not configured" do
    sign_in @user
    get new_push_path(tab: "text")
    assert_response :success
    # In test env smtp_configured? is false, so the form must not expose the field
    assert_select "input[name=?]", "push[notify_emails_to]", count: 0
  end

  test "creating push with multiple notify_emails_to and locale sends to all and uses locale when logged in" do
    sign_in @user
    assert_emails 1 do
      perform_enqueued_jobs do
        post pushes_path, params: {
          push: {
            kind: "text",
            payload: "secret",
            notify_emails_to: "first@example.com, second@example.com",
            notify_emails_to_locale: "en"
          }
        }
      end
    end
    mail = ActionMailer::Base.deliveries.last
    assert_equal ["first@example.com", "second@example.com"], mail.to
    push = Push.last
    assert_includes mail.body.encoded, push.url_token
    assert_includes mail.body.encoded, "locale=en"
  end
end
