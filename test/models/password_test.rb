# frozen_string_literal: true

require "test_helper"

class PasswordTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  teardown do
    Settings.reload!
  end

  test "should create password with name" do
    password = Push.new(
      kind: "text",
      payload: "test_payload",
      name: "Test Password"
    )
    assert password.save
    assert_equal "Test Password", password.name
  end

  test "should save password without name" do
    password = Push.new(
      kind: "text",
      payload: "test_payload"
    )
    assert password.save
    assert_equal "", password.name
  end

  test "should include name in json representation when owner is true" do
    password = Push.new(
      kind: "text",
      payload: "test_payload",
      name: "Test Password",
      expire_after_days: 7,
      expire_after_views: 10
    )
    assert password.save

    json = JSON.parse(password.to_json({owner: true}))
    assert_equal "Test Password", json["name"]
  end

  test "should not include name in json representation when owner is false" do
    password = Push.new(
      kind: "text",
      payload: "test_payload",
      name: "Test Password",
      expire_after_days: 7,
      expire_after_views: 10
    )
    assert password.save

    json = JSON.parse(password.to_json({}))
    assert_not json.key?("name")
  end

  test "should save password if share_recipients and share_locale are set and user is defined" do
    Settings.mail.smtp_address = "smtp.example.com"

    password = Push.new(
      kind: "text",
      payload: "test_payload",
      share_recipients: "test@example.com",
      share_locale: "fr",
      user: users(:luca)
    )

    assert password.valid?
  end

  test "send_creation_emails enqueues job when share_recipients present" do
    password = Push.new(
      kind: "text",
      payload: "test_payload",
      share_recipients: "test@example.com",
      share_locale: "fr",
      user: users(:luca)
    )
    password.save

    assert_enqueued_with(job: SendPushCreatedEmailJob, args: [password.id]) do
      password.send_creation_emails
    end
  end

  test "should reject more than 5 emails in share_recipients for pushes" do
    emails = 6.times.map { |i| "u#{i}@example.com" }.join(", ")
    password = Push.new(
      kind: "text",
      payload: "test_payload",
      share_recipients: emails
    )

    assert_not password.valid?
    assert password.errors[:share_recipients].any? { |m| m.include?("5") || m.include?("at most") }
  end

  test "should reject invalid share_locale for pushes" do
    password = Push.new(
      kind: "text",
      payload: "test_payload",
      share_recipients: "test@example.com",
      share_locale: "zz"
    )

    assert_not password.valid?
    assert password.errors[:share_locale].present?
  end

  test "should not save password if email service is not configured" do
    password = Push.new(
      kind: "text",
      payload: "test_payload",
      share_recipients: "test@example.com",
      share_locale: "en",
      user: users(:luca)
    )

    refute password.valid?
    assert_includes password.errors[:share_recipients], "is using emails, but sending emails feature is not enabled."
    assert_includes password.errors[:share_locale], "is using emails, but sending emails feature is not enabled."
  end

  test "should not save password if share_recipients and share_locale are set and user is not defined" do
    password = Push.new(
      kind: "text",
      payload: "test_payload",
      share_recipients: "test@example.com",
      share_locale: "en"
    )

    refute password.valid?
    assert_includes password.errors[:share_recipients], "cannot be set if owner is not known."
    assert_includes password.errors[:share_locale], "cannot be set if owner is not known."
  end

  test "to_json excludes share and share_locale ciphertext and virtual attributes" do
    Settings.mail.smtp_address = "smtp.example.com"
    password = Push.new(
      kind: "text",
      payload: "test_payload",
      share_recipients: "test@example.com",
      share_locale: "fr",
      user: users(:luca)
    )
    password.save

    sensitive_keys = %w[
      share_ciphertext
      share_locale_ciphertext
      share
      share_locale
    ]
    [{}, {owner: true}, {payload: true}, {owner: true, payload: true}].each do |opts|
      json = JSON.parse(password.to_json(opts))
      sensitive_keys.each do |key|
        assert_not json.key?(key), "to_json(#{opts.inspect}) must not include #{key}"
      end
    end
  end
end
