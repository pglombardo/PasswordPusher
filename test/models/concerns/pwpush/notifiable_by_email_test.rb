# frozen_string_literal: true

require "test_helper"

class Pwpush::NotifiableByEmailTest < ActiveSupport::TestCase
  setup do
    Settings.mail.smtp_address = "smtp.example.com"

    @push = pushes(:test_push)

    @user = @push.user
    @other_user = users(:luca)

    @push.notify_emails_to_required = true
    @push.notify_emails_to = "test@example.com"
    @push.notify_emails_to_locale = "fr"
    @push.notify_by_email_creator = @user
  end

  teardown do
    Settings.reload!
  end

  test "does not require notify_emails_to when notify_emails_to_required is false" do
    @push.notify_emails_to_required = false
    @push.notify_emails_to = nil

    assert @push.valid?
  end

  # Test notify_emails_to validation - presence when required
  test "validates presence of notify_emails_to when notify_emails_to_required is true" do
    @push.notify_emails_to = nil

    assert_not @push.valid?
    assert_includes @push.errors[:notify_emails_to], "can't be blank"
  end

  # Test notify_emails_to_locale validation
  test "accepts valid locale in notify_emails_to_locale" do
    @push.notify_emails_to_locale = "en"

    assert @push.valid?
  end

  test "accepts empty locale in notify_emails_to_locale" do
    @push.notify_emails_to_locale = ""

    assert @push.valid?
  end

  test "accepts blank notify_emails_to_locale" do
    @push.notify_emails_to_locale = nil

    assert @push.valid?
  end

  test "rejects invalid locale in notify_emails_to_locale" do
    @push.notify_emails_to_locale = "invalid_locale"

    assert_not @push.valid?
    assert_includes @push.errors[:notify_emails_to_locale], "is not included in the list"
  end

  # Test notify_by_email_availability validation
  test "rejects email notification when feature is not enabled" do
    Settings.mail.smtp_address = nil

    assert_not @push.valid?
    assert_includes @push.errors[:notify_emails_to], "is not available"
    assert_includes @push.errors[:notify_emails_to_locale], "is not available"
    assert_includes @push.errors[:base], "Notify by email feature is not enabled"
  end

  test "rejects email notification when creator is not set" do
    @push.notify_by_email_creator = nil

    assert_not @push.valid?
    assert_includes @push.errors[:notify_emails_to], "is not allowed for unknown users"
    assert_includes @push.errors[:notify_emails_to_locale], "is not allowed for unknown users"
  end

  test "rejects email notification when creator does not match push user" do
    @push.notify_by_email_creator = @other_user

    assert @other_user != @user
    assert_not @push.valid?
    assert_includes @push.errors[:notify_emails_to], "is allowed for only owners"
    assert_includes @push.errors[:notify_emails_to_locale], "is allowed for only owners"
  end

  # Test notify_by_email_limit validation
  test "accepts up to 5 email recipients for a new push" do
    push = Push.new(kind: "text", payload: "test", user: @user)

    emails = Array.new(5) { |i| "user#{i}@example.com" }.join(",")
    push.notify_emails_to = emails
    push.notify_by_email_creator = @user

    assert push.valid?
  end

  test "rejects more than 5 email recipients for a new push" do
    push = Push.new(kind: "text", payload: "test", user: @user)

    emails = Array.new(6) { |i| "user#{i}@example.com" }.join(",")
    push.notify_emails_to = emails
    push.notify_by_email_creator = @user

    refute push.valid?
    assert_includes push.errors[:notify_emails_to], "contains more than 5 email(s)"
  end

  test "accepts emails within remaining limit for existing push with previous notifications" do
    notify_by_email = notify_by_emails(:one)

    assert_equal 1, notify_by_email.recipients_count

    emails = Array.new(4) { |i| "user#{i}@example.com" }.join(",")
    @push.notify_emails_to = emails

    assert @push.valid?
  end

  test "rejects emails when remaining limit is exceeded for a new push with previous notifications" do
    notify_by_email = notify_by_emails(:one)

    assert_equal 1, notify_by_email.recipients_count

    emails = Array.new(5) { |i| "user#{i}@example.com" }.join(",")
    @push.notify_emails_to = emails

    assert_not @push.valid?
    assert_includes @push.errors[:base], "You can notify up to 5 email(s) and you have already sent emails to 1 recipients"
  end

  test "rejects email notification for an expired push" do
    @push.notify_emails_to = nil
    @push.notify_emails_to_locale = nil
    @push.notify_emails_to_required = false
    @push.expire!
    @push.notify_emails_to = "test@example.com"
    @push.notify_emails_to_locale = "en"

    assert_not @push.valid?
    assert_includes @push.errors[:notify_emails_to], "is not available for expired pushes"
    assert_includes @push.errors[:notify_emails_to_locale], "is not available for expired pushes"
  end

  # Test associations
  test "has_many notify_by_emails_audit_logs returns audit logs with creation_email_send kind" do
    assert @push.notify_by_emails_audit_logs.exists?
    assert @push.notify_by_emails_audit_logs.all? { |log| log.creation_email_send? }
  end

  test "has_many notify_by_emails through audit logs" do
    assert_equal 1, @push.notify_by_emails.count
    assert @push.notify_by_emails.first.is_a?(NotifyByEmail)
  end

  # Test multiple_emails validator integration
  test "rejects invalid email format in notify_emails_to" do
    @push.notify_emails_to = "invalid-email-format"

    assert_not @push.valid?
    assert @push.errors[:notify_emails_to].any? { |m| m.include?("invalid email") }
  end

  # Test attr_accessor attributes
  test "notify_emails_to is accessible" do
    @push.notify_emails_to = "test@example.com"
    assert_equal "test@example.com", @push.notify_emails_to
  end

  test "notify_emails_to_locale is accessible" do
    @push.notify_emails_to_locale = "fr"
    assert_equal "fr", @push.notify_emails_to_locale
  end

  test "notify_emails_to_required is accessible" do
    @push.notify_emails_to_required = true
    assert_equal true, @push.notify_emails_to_required
  end

  test "notify_by_email_creator is accessible" do
    @push.notify_by_email_creator = @user
    assert_equal @user, @push.notify_by_email_creator
  end
end
