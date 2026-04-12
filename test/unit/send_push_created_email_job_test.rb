# frozen_string_literal: true

require "test_helper"

class SendPushCreatedEmailJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper
  setup do
    Rails.application.routes.default_url_options[:host] = "test.host"
    @push = pushes(:test_push)
    @push.update(notify_emails_to: "test@example.com, test2@example.com")
  end

  test "sends email to specified recipient" do
    SendPushCreatedEmailJob.perform_now(@push)

    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      SendPushCreatedEmailJob.perform_now(@push)
      assert_equal ["test@example.com", "test2@example.com"], ActionMailer::Base.deliveries.first.to
      assert_equal "#{@push.user.email} has sent you a push", ActionMailer::Base.deliveries.first.subject
    end
  end

  test "logs creation email event" do
    SendPushCreatedEmailJob.perform_now(@push)

    assert_equal 1, @push.audit_logs.where(kind: :creation_email_send).count
  end

  test "job executes without exceptions" do
    assert_nothing_raised do
      SendPushCreatedEmailJob.perform_now(@push)
    end
  end

  test "perform sends mail when notify_emails_to present" do
    assert_emails 1 do
      SendPushCreatedEmailJob.perform_now(@push.id)
    end
  end

  test "perform creates audit log with kind creation_email_send after sending" do
    assert_difference "@push.audit_logs.count", 1 do
      SendPushCreatedEmailJob.perform_now(@push.id)
    end
    assert_audit_log_created(@push, :creation_email_send)
  end

  test "perform does not send mail when notify_emails_to blank" do
    @push.update(notify_emails_to: "")

    assert_emails 0 do
      SendPushCreatedEmailJob.perform_now(@push.id)
    end
  end

  test "perform does not send mail when push is missing" do
    assert_emails 0 do
      invalid_id = -1
      SendPushCreatedEmailJob.perform_now(invalid_id)
    end
  end

  test "perform delivers to correct addresses" do
    SendPushCreatedEmailJob.perform_now(@push.id)

    mail = ActionMailer::Base.deliveries.last
    assert_equal ["job@example.com"], mail.to
  end

  test "perform uses default queue" do
    assert_equal "default", SendPushCreatedEmailJob.new.queue_name
  end
end
