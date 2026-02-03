# frozen_string_literal: true

require "test_helper"

class NotifyEmailsCreationTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    Rails.application.routes.default_url_options[:host] = "test.host"
  end

  test "creating push with notify_emails_to enqueues SendPushCreatedEmailJob" do
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

  test "creating push with notify_emails_to sends email when jobs performed" do
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

  test "creating push with invalid notify_emails_to does not create push" do
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
end
