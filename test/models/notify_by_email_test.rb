# frozen_string_literal: true

require "test_helper"

class NotifyByEmailTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @push = pushes(:test_push)
    @user = users(:giuliana)
    @push.notify_by_email_recipients = "one@example.com, two@example.com"
    @push.notify_by_email_locale = "en"

    # Create an audit log with user for proper testing
    @audit_log = AuditLog.build(
      push: @push,
      kind: :creation_email_send,
      user: @user,
      ip: "127.0.0.1"
    )

    travel_to Time.current.beginning_of_day + 6.hours
  end

  teardown do
    travel_back
  end

  # Test associations
  test "should belong to audit_log" do
    notify = NotifyByEmail.new
    assert_not notify.valid?
    assert_includes notify.errors[:audit_log], "must exist"

    notify.audit_log = @audit_log
    notify.recipients = "test@example.com"
    assert notify.valid?
  end

  test "should have push through audit_log" do
    notify = notify_by_emails(:one)
    assert_equal @push, notify.push
  end

  test "should have user through audit_log" do
    @audit_log.save!

    assert_equal @user, @audit_log.notify_by_email.user
  end

  # Test status enum
  test "should have valid status values" do
    valid_statuses = [:pending, :processing, :completed, :partially_failed, :failed]

    valid_statuses.each do |status|
      notify = NotifyByEmail.new(
        audit_log: @audit_log,
        recipients: "test@example.com",
        status: status
      )
      assert notify.valid?, "#{status} should be a valid status"
    end
  end

  test "should not accept invalid status" do
    notify = NotifyByEmail.new(
      audit_log: @audit_log,
      recipients: "test@example.com",
      status: :invalid_status
    )
    assert_not notify.valid?
    assert_includes notify.errors[:status], "is not included in the list"
  end

  test "default status should be pending" do
    notify = NotifyByEmail.new(audit_log: @audit_log, recipients: "test@example.com")
    assert notify.pending?
  end

  # Test readonly attributes
  test "recipients should be readonly after creation" do
    notify = notify_by_emails(:one)

    assert_raises(ActiveRecord::ReadonlyAttributeError) do
      notify.recipients = "changed@example.com"
      notify.save
    end
  end

  test "recipients_count should be readonly after creation" do
    notify = notify_by_emails(:one)

    assert_raises(ActiveRecord::ReadonlyAttributeError) do
      notify.recipients_count = 99
      notify.save
    end
  end

  test "locale should be readonly after creation" do
    notify = notify_by_emails(:one)

    assert_raises(ActiveRecord::ReadonlyAttributeError) do
      notify.locale = "fr"
      notify.save
    end
  end

  test "audit_log_id should be readonly after creation" do
    other_audit_log = audit_logs(:creation)
    notify = notify_by_emails(:one)

    assert_raises(ActiveRecord::ReadonlyAttributeError) do
      notify.audit_log_id = other_audit_log.id
      notify.save
    end
  end

  # Test set_recipients_count callback
  test "set_recipients_count sets count based on single recipient" do
    @push.notify_by_email_recipients = "test@example.com"
    @audit_log.save!

    assert_equal 1, @audit_log.notify_by_email.recipients_count
  end

  test "set_recipients_count sets count based on multiple recipients" do
    @audit_log.save!

    assert_equal 2, @audit_log.notify_by_email.recipients_count
  end

  # Test increment_email_sent_count
  test "increment_email_sent_count updates user email_sent_count on first email of day" do
    @user.update(email_sent_count: 0, email_sent_count_reset_at: nil)

    @audit_log.save!

    @user.reload
    assert_equal 2, @user.email_sent_count
    assert @user.email_sent_count_reset_at.present?
  end

  test "increment_email_sent_count increments user email_sent_count on subsequent emails same day" do
    @user.update(email_sent_count: 2, email_sent_count_reset_at: Time.current)

    @audit_log.save!

    @user.reload
    assert_equal 4, @user.email_sent_count
  end

  test "increment_email_sent_count resets count when new day starts" do
    @user.update(email_sent_count: 10, email_sent_count_reset_at: 1.day.ago)

    @audit_log.save!

    @user.reload
    assert_equal 2, @user.email_sent_count
  end

  # Test send_notify_by_email callback
  test "send_notify_by_email enqueues SendNotifyByEmailJob after creation" do
    assert_enqueued_jobs 1, only: SendNotifyByEmailJob do
      @audit_log.save!
    end
  end

  # Test encrypted attributes
  test "recipients is encrypted" do
    notify = NotifyByEmail.build(
      audit_log: @audit_log,
      recipients: "encrypted@example.com"
    )

    assert_equal "encrypted@example.com", notify.recipients
    assert_not_equal "encrypted@example.com", notify.recipients_ciphertext
  end

  test "locale is encrypted" do
    notify = NotifyByEmail.build(
      audit_log: @audit_log,
      recipients: "test@example.com",
      locale: "fr"
    )

    assert_equal "fr", notify.locale
    assert_not_equal "fr", notify.locale_ciphertext
  end

  test "successful_sends is encrypted" do
    notify = NotifyByEmail.build(
      audit_log: @audit_log,
      recipients: "test@example.com",
      successful_sends: "success@example.com"
    )

    assert_equal "success@example.com", notify.successful_sends
    assert_not_equal "success@example.com", notify.successful_sends_ciphertext
  end

  test "error_message is encrypted" do
    notify = NotifyByEmail.build(
      audit_log: @audit_log,
      recipients: "test@example.com",
      error_message: "Error occurred"
    )

    assert_equal "Error occurred", notify.error_message
    assert_not_equal "Error occurred", notify.error_message_ciphertext
  end
end
