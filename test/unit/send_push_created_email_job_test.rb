# frozen_string_literal: true

require "test_helper"

class SendPushCreatedEmailJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper
  setup do
    Rails.application.routes.default_url_options[:host] = "test.host"
    @push = Push.create!(
      kind: "text",
      payload: "secret",
      url_token: "jobtest123",
      notify_emails_to: "job@example.com"
    )
  end

  test "perform sends mail when notify_emails_to present" do
    assert_emails 1 do
      SendPushCreatedEmailJob.perform_now(@push)
    end
  end

  test "perform does not send mail when notify_emails_to blank" do
    @push.update_column(:notify_emails_to, nil)

    assert_emails 0 do
      SendPushCreatedEmailJob.perform_now(@push)
    end
  end

  test "perform delivers to correct addresses" do
    SendPushCreatedEmailJob.perform_now(@push)

    mail = ActionMailer::Base.deliveries.last
    assert_equal ["job@example.com"], mail.to
  end

  test "job is enqueued with push" do
    assert_enqueued_with(job: SendPushCreatedEmailJob, args: [@push]) do
      SendPushCreatedEmailJob.perform_later(@push)
    end
  end
end
