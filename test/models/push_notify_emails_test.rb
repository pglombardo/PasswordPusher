# frozen_string_literal: true

require "test_helper"

class PushNotifyEmailsTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  setup do
    @user = users(:luca)
    Rails.application.routes.default_url_options[:host] = "test.host"
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
    assert push.errors[:notify_emails_to].any? { |m| m.include?("invalid") }
  end

  test "push rejects more than 5 emails in notify_emails_to" do
    emails = 6.times.map { |i| "u#{i}@example.com" }.join(", ")
    push = Push.new(
      kind: "text",
      payload: "secret",
      notify_emails_to: emails
    )
    assert_not push.valid?
    assert push.errors[:notify_emails_to].any? { |m| m.include?("5") || m.include?("at most") }
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
    assert push.errors[:notify_emails_to].any? { |m| m =~ /duplicate/i }
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

  test "to_json excludes notify_emails_to and notify_emails_to_locale ciphertext and virtual attributes" do
    push = Push.create!(
      kind: "text",
      payload: "secret",
      user: @user,
      notify_emails_to: "recipient@example.com",
      notify_emails_to_locale: "fr"
    )
    sensitive_keys = %w[
      notify_emails_to_ciphertext
      notify_emails_to_locale_ciphertext
      notify_emails_to
      notify_emails_to_locale
    ]
    [{}, {owner: true}, {payload: true}, {owner: true, payload: true}].each do |opts|
      json = JSON.parse(push.to_json(opts))
      sensitive_keys.each do |key|
        assert_not json.key?(key), "to_json(#{opts.inspect}) must not include #{key}"
      end
    end
  end
end
