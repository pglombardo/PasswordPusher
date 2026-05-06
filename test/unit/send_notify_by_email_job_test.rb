# frozen_string_literal: true

require "test_helper"

class SendNotifyByEmailJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper
  setup do
    Settings.mail.smtp_address = "smtp.example.com"

    @push = pushes(:test_push)
    @notify_by_email = notify_by_emails(:one)
  end

  teardown do
    Settings.reload!
  end

  test "sends email to specified recipient" do
    mails = capture_emails do
      SendNotifyByEmailJob.perform_now(@notify_by_email.id)
    end

    mail = mails.first
    assert_equal ["one@example.com"], mail.to
    assert_equal "#{@push.user.email} has sent you a push", mail.subject
  end

  test "perform update notify_by_email status to completed after sending" do
    SendNotifyByEmailJob.perform_now(@notify_by_email.id)

    @notify_by_email.reload
    assert_equal "completed", @notify_by_email.status
    assert_equal "one@example.com", @notify_by_email.successful_sends
  end

  test "perform update notify_by_email status to failed after sending" do
    failing_mail = Minitest::Mock.new
    failing_mail.expect(:deliver_now, -> { raise StandardError, "test error" })

    PushCreatedMailer.stub(:with, failing_mail) do
      SendNotifyByEmailJob.perform_now(@notify_by_email.id)
    end

    @notify_by_email.reload
    assert_equal "failed", @notify_by_email.status
    assert_equal "", @notify_by_email.successful_sends
    assert_equal "No emails were sent successfully.", @notify_by_email.error_message
  end

  test "perform does not send mail when notify_by_email is not pending" do
    @notify_by_email.update(status: "processing")
    assert_emails 0 do
      SendNotifyByEmailJob.perform_now(@notify_by_email.id)
    end
  end

  test "perform does not send mail when recipients are blank" do
    # Bypass readonly attribute
    @notify_by_email.update_columns(recipients_ciphertext: "")
    SendNotifyByEmailJob.perform_now(@notify_by_email.id)

    @notify_by_email.reload
    assert_equal "failed", @notify_by_email.status
    assert @notify_by_email.successful_sends.blank?
    assert_equal "No recipients found.", @notify_by_email.error_message
  end

  test "perform does not send mail when notifying by email is not available" do
    Settings.mail.smtp_address = nil

    SendNotifyByEmailJob.perform_now(@notify_by_email.id)

    @notify_by_email.reload
    assert_equal "failed", @notify_by_email.status, "Status should be failed"
    assert_equal "Notifying by email is not available.", @notify_by_email.error_message
  end

  test "perform logs error and does not send mail if notify_by_email is not found" do
    invalid_id = -1
    logger = Minitest::Mock.new
    logger.expect(:error, nil, ["[SendNotifyByEmailJob] NotifyByEmail not found: #{invalid_id}"])

    Rails.stub(:logger, logger) do
      SendNotifyByEmailJob.perform_now(invalid_id)
    end

    assert logger.verify
  end

  test "perform uses default queue" do
    assert_equal "default", SendNotifyByEmailJob.new.queue_name
  end
end
