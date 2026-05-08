# frozen_string_literal: true

require "test_helper"

class Pwpush::NotifiableByEmailTest < ActiveSupport::TestCase
  setup do
    Settings.mail.smtp_address = "smtp.example.com"

    @user = users(:giuliana)
    @other_user = users(:luca)
    @push = pushes(:test_push)
    @push.notify_by_email_required = true
    @push.notify_by_email_recipients = "test@example.com"
    @push.notify_by_email_creator = @user

    @original_cache_store = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Settings.reload!
    Rails.cache = @original_cache_store
  end

  test "does not require notify_by_email_recipients when notify_by_email_required is false" do
    @push.notify_by_email_required = false
    @push.notify_by_email_recipients = nil

    assert @push.valid?
  end

  # Test notify_by_email_recipients validation - presence when required
  test "validates presence of notify_by_email_recipients when notify_by_email_required is true" do
    @push.notify_by_email_recipients = nil

    assert_not @push.valid?
    assert_includes @push.errors[:notify_by_email_recipients], "can't be blank"
  end

  # Test notify_by_email_locale validation
  test "accepts valid locale in notify_by_email_locale" do
    @push.notify_by_email_locale = "en"

    assert @push.valid?
  end

  test "accepts blank notify_by_email_locale" do
    @push.notify_by_email_locale = nil

    assert @push.valid?
  end

  test "rejects invalid locale in notify_by_email_locale" do
    @push.notify_by_email_locale = "invalid_locale"

    assert_not @push.valid?
    assert_includes @push.errors[:notify_by_email_locale], "is not included in the list"
  end

  # Test notify_by_email_availability validation
  test "rejects email notification when feature is not enabled" do
    Settings.mail.smtp_address = nil

    @push.notify_by_email_recipients = "test@example.com"

    assert_not @push.valid?
    assert_includes @push.errors[:base], "Notifying by email is not available"
  end

  test "rejects email notification when creator is not set" do
    @push.notify_by_email_creator = nil

    assert_not @push.valid?
    assert_includes @push.errors[:base], "Notifying by email is not allowed for unknown users"
  end

  test "rejects email notification when creator does not match push user" do
    @push.notify_by_email_creator = @other_user

    assert_not @push.valid?
    assert_includes @push.errors[:base], "Notifying by email is allowed for only owners"
  end

  # Test notify_by_email_limit validation
  test "accepts up to 5 email recipients for a new push" do
    push = Push.new(kind: "text", payload: "test", user: @user)

    emails = Array.new(5) { |i| "user#{i}@example.com" }.join(",")
    push.notify_by_email_recipients = emails
    push.notify_by_email_creator = @user

    assert push.valid?
  end

  test "rejects more than 5 email recipients for a new push" do
    push = Push.new(kind: "text", payload: "test", user: @user)

    emails = Array.new(6) { |i| "user#{i}@example.com" }.join(",")
    push.notify_by_email_recipients = emails

    assert_not push.valid?
    assert_includes push.errors[:base], "You can notify up to 5 email(s)"
  end

  test "accepts emails within remaining limit for existing push with previous notifications" do
    notify_by_email = notify_by_emails(:one)

    assert_equal 1, notify_by_email.recipients_count

    emails = Array.new(4) { |i| "user#{i}@example.com" }.join(",")
    @push.notify_by_email_recipients = emails

    assert @push.valid?
  end

  test "rejects emails when remaining limit is exceeded for a new push with previous notifications" do
    notify_by_email = notify_by_emails(:one)

    assert_equal 1, notify_by_email.recipients_count

    emails = Array.new(5) { |i| "user#{i}@example.com" }.join(",")
    @push.notify_by_email_recipients = emails

    assert_not @push.valid?
    assert_includes @push.errors[:base], "You can notify up to 5 email(s) and you have already sent emails to 1 recipients"
  end

  test "rejects email notification for an expired push" do
    @push.notify_by_email_recipients = nil
    @push.notify_by_email_required = false
    @push.expire!
    @push.notify_by_email_recipients = "test@example.com"

    assert_not @push.valid?
    assert_includes @push.errors[:base], "You cannot notify by email for an expired push."
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
  test "rejects invalid email format in notify_by_email_recipients" do
    @push.notify_by_email_recipients = "invalid-email-format"

    assert_not @push.valid?
    assert @push.errors[:notify_by_email_recipients].any? { |m| m.include?("invalid email") }
  end

  # Test attr_accessor attributes
  test "notify_by_email_recipients is accessible" do
    @push.notify_by_email_recipients = "test@example.com"
    assert_equal "test@example.com", @push.notify_by_email_recipients
  end

  test "notify_by_email_locale is accessible" do
    @push.notify_by_email_locale = "fr"
    assert_equal "fr", @push.notify_by_email_locale
  end

  test "notify_by_email_required is accessible" do
    @push.notify_by_email_required = true
    assert_equal true, @push.notify_by_email_required
  end

  test "notify_by_email_creator is accessible" do
    @push.notify_by_email_creator = @user
    assert_equal @user, @push.notify_by_email_creator
  end

  # Test notify_by_email_daily_limit_reached? method
  test "notify_by_email_daily_limit_reached? returns false when under daily limit" do
    Rails.cache.clear
    cache_key = "notify_by_email_daily_usage_#{@push.user.id}_#{Time.current.beginning_of_day.to_i}"
    Rails.cache.write(cache_key, 90)

    assert_not @push.notify_by_email_daily_limit_reached?
  end

  test "notify_by_email_daily_limit_reached? returns true when over daily limit" do
    Rails.cache.clear
    cache_key = "notify_by_email_daily_usage_#{@push.user.id}_#{Time.current.beginning_of_day.to_i}"
    Rails.cache.write(cache_key, 150)

    assert @push.notify_by_email_daily_limit_reached?
  end

  # Test daily rate limit validation
  test "rejects email notification when daily rate limit is reached" do
    Rails.cache.clear
    cache_key = "notify_by_email_daily_usage_#{@push.user.id}_#{Time.current.beginning_of_day.to_i}"
    Rails.cache.write(cache_key, 100)

    assert_not @push.valid?
    assert_includes @push.errors[:base], "The maximum number of emails has been reached for today"
  end

  test "accepts email notification when just under daily rate limit" do
    Rails.cache.clear
    cache_key = "notify_by_email_daily_usage_#{@push.user.id}_#{Time.current.beginning_of_day.to_i}"
    Rails.cache.write(cache_key, 99)

    assert @push.valid?
  end
end
