# frozen_string_literal: true

require "test_helper"

class SendPushCreatedEmailJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper
  setup do
    Rails.application.routes.default_url_options[:host] = "test.host"
    @push = pushes(:test_push)
    @share_by_email = share_by_emails(:one)
  end

  test "sends email to specified recipient" do
    mails = capture_emails do
      SendPushCreatedEmailJob.perform_now(@share_by_email.id)
    end

    mail = mails.first
    assert_equal ["one@example.com"], mail.to
    assert_equal "#{@push.user.email} has sent you a push", mail.subject
  end

  test "perform update share_by_email status to completed after sending" do
    SendPushCreatedEmailJob.perform_now(@share_by_email.id)

    @share_by_email.reload
    assert_equal "completed", @share_by_email.status
    assert_equal "one@example.com", @share_by_email.successful_sends
  end

  test "perform update share_by_email status to fully_failed after sending" do
    failing_mail = Minitest::Mock.new
    failing_mail.expect(:deliver_now, -> { raise StandardError, "test error" })

    PushCreatedMailer.stub(:with, failing_mail) do
      SendPushCreatedEmailJob.perform_now(@share_by_email.id)
    end

    @share_by_email.reload
    assert_equal "fully_failed", @share_by_email.status
    assert_equal "", @share_by_email.successful_sends
  end

  test "perform does not send mail when share_by_email is not pending" do
    @share_by_email.update(status: "processing")
    assert_emails 0 do
      SendPushCreatedEmailJob.perform_now(@share_by_email.id)
    end
  end

  test "perform does not send mail when recipients are blank" do
    # Bypass readonly attribute
    @share_by_email.update_columns(recipients_ciphertext: "")
    SendPushCreatedEmailJob.perform_now(@share_by_email.id)

    @share_by_email.reload
    assert_equal "pending", @share_by_email.status
    assert_nil @share_by_email.successful_sends
  end

  test "perform does not send mail when share_by_email is not found" do
    assert_emails 0 do
      invalid_id = -1
      SendPushCreatedEmailJob.perform_now(invalid_id)
    end
  end

  test "perform uses default queue" do
    assert_equal "default", SendPushCreatedEmailJob.new.queue_name
  end
end
