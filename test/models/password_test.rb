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

  test "should save password if notify_by_email_recipients and notify_by_email_locale are set and user is defined" do
    Settings.mail.smtp_address = "smtp.example.com"

    password = Push.new(
      kind: "text",
      payload: "test_payload",
      notify_by_email_recipients: "test@example.com",
      notify_by_email_locale: "fr"
    )

    assert password.valid?
  end

  test "should reject more than 5 emails in notify_by_email_recipients for pushes" do
    emails = 6.times.map { |i| "u#{i}@example.com" }.join(", ")
    password = Push.new(
      kind: "text",
      payload: "test_payload",
      notify_by_email_recipients: emails
    )

    assert_not password.valid?
    assert password.errors[:notify_by_email_recipients].any? { |m| m.include?("5") || m.include?("at most") }
  end

  test "should reject invalid notify_by_email_locale for pushes" do
    password = Push.new(
      kind: "text",
      payload: "test_payload",
      notify_by_email_recipients: "test@example.com",
      notify_by_email_locale: "zz"
    )

    assert_not password.valid?
    assert password.errors[:notify_by_email_locale].present?
  end
end
