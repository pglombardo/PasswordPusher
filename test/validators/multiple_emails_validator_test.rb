# frozen_string_literal: true

require "test_helper"

class MultipleEmailsValidatorTest < ActiveSupport::TestCase
  class DummyRecord
    include ActiveModel::Model
    include ActiveModel::Validations
    attr_accessor :notify_emails_to

    validates :notify_emails_to, multiple_emails: true, allow_blank: true
  end

  test "allows blank" do
    r = DummyRecord.new(notify_emails_to: nil)
    assert r.valid?
    r.notify_emails_to = ""
    assert r.valid?
  end

  test "allows single valid email" do
    r = DummyRecord.new(notify_emails_to: "user@example.com")
    assert r.valid?, r.errors.full_messages.join(", ")
  end

  test "allows multiple valid emails comma-separated" do
    r = DummyRecord.new(notify_emails_to: "a@x.com, b@y.co, c@z.org")
    assert r.valid?, r.errors.full_messages.join(", ")
  end

  test "allows up to 5 emails" do
    r = DummyRecord.new(notify_emails_to: "a@x.com, b@x.com, c@x.com, d@x.com, e@x.com")
    assert r.valid?, r.errors.full_messages.join(", ")
  end

  test "rejects more than 5 emails" do
    r = DummyRecord.new(notify_emails_to: "a@x.com, b@x.com, c@x.com, d@x.com, e@x.com, f@x.com")
    assert_not r.valid?
    assert r.errors[:notify_emails_to].present?
  end

  test "rejects duplicate emails" do
    r = DummyRecord.new(notify_emails_to: "a@x.com, a@x.com")
    assert_not r.valid?
    assert r.errors[:notify_emails_to].any? { |m| m.include?("Duplicate") }
  end

  test "rejects invalid email format" do
    r = DummyRecord.new(notify_emails_to: "not-an-email")
    assert_not r.valid?
    assert r.errors[:notify_emails_to].present?
  end

  test "rejects mixed valid and invalid emails" do
    r = DummyRecord.new(notify_emails_to: "good@example.com, bad")
    assert_not r.valid?
    assert r.errors[:notify_emails_to].present?
  end

  test "strips whitespace around emails" do
    r = DummyRecord.new(notify_emails_to: "  a@x.com  ,  b@y.com  ")
    assert r.valid?, r.errors.full_messages.join(", ")
  end

  test "rejects exactly 6 emails" do
    emails = 6.times.map { |i| "u#{i}@example.com" }.join(", ")
    r = DummyRecord.new(notify_emails_to: emails)
    assert_not r.valid?
    assert r.errors[:notify_emails_to].any? { |m| m.include?("5") || m.include?("at most") }
  end

  test "duplicate check is case-sensitive" do
    # Different case is treated as different email by current implementation
    r = DummyRecord.new(notify_emails_to: "user@Example.com, user@example.com")
    assert r.valid?, r.errors.full_messages.join(", ")
  end
end
