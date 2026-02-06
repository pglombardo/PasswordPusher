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
      SendPushCreatedEmailJob.perform_now(@push.id)
    end
  end

  test "perform does not send mail when notify_emails_to blank" do
    @push.update_column(:notify_emails_to, nil)

    assert_emails 0 do
      SendPushCreatedEmailJob.perform_now(@push.id)
    end
  end

  test "perform does not send mail when push is missing" do
    assert_emails 0 do
      SendPushCreatedEmailJob.perform_now(-1)
    end
  end

  test "perform delivers to correct addresses" do
    SendPushCreatedEmailJob.perform_now(@push.id)

    mail = ActionMailer::Base.deliveries.last
    assert_equal ["job@example.com"], mail.to
  end

  test "perform delivers to multiple addresses when notify_emails_to has several" do
    @push.update!(notify_emails_to: "a@example.com, b@example.com")
    SendPushCreatedEmailJob.perform_now(@push.id)

    mail = ActionMailer::Base.deliveries.last
    assert_equal ["a@example.com", "b@example.com"], mail.to
  end

  test "job is enqueued with push id" do
    assert_enqueued_with(job: SendPushCreatedEmailJob, args: [@push.id]) do
      SendPushCreatedEmailJob.perform_later(@push.id)
    end
  end

  test "perform sends mail with subject containing has sent you a Push" do
    SendPushCreatedEmailJob.perform_now(@push.id)
    mail = ActionMailer::Base.deliveries.last
    assert mail.subject.present?
    assert_includes mail.subject, "has sent you a Push"
  end

  test "perform sends mail body containing push secret URL" do
    SendPushCreatedEmailJob.perform_now(@push.id)
    mail = ActionMailer::Base.deliveries.last
    assert_includes mail.body.encoded, @push.url_token
  end

  test "perform uses default queue" do
    assert_equal "default", SendPushCreatedEmailJob.new.queue_name
  end

  test "perform does not send when push has blank string notify_emails_to" do
    @push.update_column(:notify_emails_to, "")

    assert_emails 0 do
      SendPushCreatedEmailJob.perform_now(@push.id)
    end
  end
end
