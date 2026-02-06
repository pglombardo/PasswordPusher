# frozen_string_literal: true

require "test_helper"

class PushNotifyEmailsTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  setup do
    @user = users(:luca)
    Settings.enable_logins = true
    Rails.application.routes.default_url_options[:host] = "test.host"
  end

  teardown do
    Settings.enable_logins = false
  end

  test "push accepts valid notify_emails_to" do
    push = Push.new(
      kind: "text",
      payload: "secret",
      notify_emails_to: "a@example.com, b@example.com"
    )
    push.valid?
    assert push.valid?, push.errors.full_messages.join(", ")
  end

  test "push rejects invalid notify_emails_to format" do
    push = Push.new(
      kind: "text",
      payload: "secret",
      notify_emails_to: "not-an-email"
    )
    assert_not push.valid?
    assert push.errors[:base].any? { |m| m.include?("invalid") }
  end

  test "push rejects more than 5 emails in notify_emails_to" do
    emails = 6.times.map { |i| "u#{i}@example.com" }.join(", ")
    push = Push.new(
      kind: "text",
      payload: "secret",
      notify_emails_to: emails
    )
    assert_not push.valid?
    assert push.errors[:base].any? { |m| m.include?("5") || m.include?("at most") }
  end

  test "send_creation_emails does nothing when notify_emails_to blank" do
    push = Push.create!(
      kind: "text",
      payload: "secret",
      user: @user,
      notify_emails_to: nil
    )
    assert_no_enqueued_jobs(only: SendPushCreatedEmailJob) do
      push.send_creation_emails
    end
  end

  test "send_creation_emails enqueues job when notify_emails_to present" do
    push = Push.create!(
      kind: "text",
      payload: "secret",
      user: @user,
      notify_emails_to: "recipient@example.com"
    )
    assert_enqueued_with(job: SendPushCreatedEmailJob, args: [push.id]) do
      push.send_creation_emails
    end
  end

  test "push rejects duplicate emails in notify_emails_to" do
    push = Push.new(
      kind: "text",
      payload: "secret",
      notify_emails_to: "a@example.com, a@example.com"
    )
    assert_not push.valid?
    assert push.errors[:base].any? { |m| m.include?("Duplicate") }
  end

  test "push accepts valid notify_emails_to_locale" do
    push = Push.new(
      kind: "text",
      payload: "secret",
      notify_emails_to: "a@example.com",
      notify_emails_to_locale: "en"
    )
    assert push.valid?, push.errors.full_messages.join(", ")
  end

  test "push rejects invalid notify_emails_to_locale" do
    push = Push.new(
      kind: "text",
      payload: "secret",
      notify_emails_to: "a@example.com",
      notify_emails_to_locale: "zz"
    )
    assert_not push.valid?
    assert push.errors[:notify_emails_to_locale].present?
  end

  test "minutes_remaining returns 0 when push is past expiry" do
    push = Push.create!(
      kind: "text",
      payload: "secret",
      user: @user,
      expire_after_days: 1,
      created_at: 2.days.ago
    )
    assert_equal 0, push.minutes_remaining
  end

  test "minutes_remaining is positive for newly created push with expire_after_days" do
    push = Push.create!(
      kind: "text",
      payload: "secret",
      user: @user,
      expire_after_days: 7
    )
    assert push.minutes_remaining >= 7 * 24 * 60 - 60, "minutes_remaining should be close to 7 days in minutes"
  end

  test "send_creation_emails in development uses perform_now" do
    push = Push.create!(
      kind: "text",
      payload: "secret",
      user: @user,
      notify_emails_to: "dev@example.com"
    )
    # In test env we're not development, so perform_later is used.
    # Stub to simulate development and assert perform_now is called (no enqueue).
    Rails.application.routes.default_url_options[:host] = "test.host"
    Rails.stub(:env, ActiveSupport::StringInquirer.new("development")) do
      assert_no_enqueued_jobs(only: SendPushCreatedEmailJob) do
        push.send_creation_emails
      end
    end
  end
end
