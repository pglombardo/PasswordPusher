# frozen_string_literal: true

require "application_system_test_case"

class NotifyByEmailTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    Settings.mail.smtp_address = "smtp.example.com"

    @push = pushes(:test_push)
    @user = @push.user
    sign_in @user
  end

  teardown do
    Settings.reload!
  end

  test "notify by email with valid recipients" do
    visit preview_push_path(@push)
    click_on "Notify by Email"

    assert_selector "input[name='push[notify_emails_to]']", count: 1
    assert_selector "input[name='push[notify_emails_to_locale]']", count: 1, visible: :hidden

    fill_in "push[notify_emails_to]", with: "test@example.com"
    click_on "Send Emails"

    assert_text "Recipient(s) are added to the queue to be sent."
  end

  test "notify by email with invalid recipients" do
    visit preview_push_path(@push)
    click_on "Notify by Email"

    fill_in "push[notify_emails_to]", with: "test@example.com, invalid-email"
    click_on "Send Emails"

    assert_text "Recipient emails contains invalid email(s)"
  end

  test "notify_by_email creation and sending emails" do
    AuditLog.destroy_all

    visit preview_push_path(@push)
    click_on "Notify by Email"

    assert_difference "NotifyByEmail.count", 1 do
      assert_enqueued_jobs 1, only: SendNotifyByEmailJob do
        fill_in "push[notify_emails_to]", with: "test@example.com, test2@example.com"
        click_on "Send Emails"

        assert_text "Recipient(s) are added to the queue to be sent."
      end
    end

    notify_by_email = NotifyByEmail.last
    emails = capture_emails do
      SendNotifyByEmailJob.perform_now(notify_by_email.id)
    end

    assert_equal 2, emails.size
    recipients = emails.map(&:to).flatten
    assert_includes recipients, "test@example.com"
    assert_includes recipients, "test2@example.com"
  end
end
