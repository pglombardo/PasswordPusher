# frozen_string_literal: true

require "test_helper"

class CleanUpExpiredPushesAfterDurationJobTest < ActiveSupport::TestCase
  setup do
    @previous_purge_after = Settings.purge_after
    Settings.purge_after = "15 days"

    # Clear all pushes before running tests
    AuditLog.delete_all
    Push.delete_all
  end

  teardown do
    Settings.purge_after = @previous_purge_after
  end

  test "job deletes anonymous expired pushes" do
    user = users(:one)

    user_expired_push = Push.create!(
      kind: :text,
      payload: "test_payload",
      url_token: "user_expired",
      expired_on: Time.now - 20.days,
      expired: true,
      user_id: user.id
    )

    AuditLog.create!(push: user_expired_push, kind: :creation, ip: "127.0.0.1")

    user_expired_soon_push = Push.create!(
      kind: :text,
      payload: "test_payload",
      url_token: "user_expired_soon",
      expired_on: Time.now - 10.days,
      expired: true,
      user_id: user.id
    )

    AuditLog.create!(push: user_expired_soon_push, kind: :creation, ip: "127.0.0.1")

    user_expired_id = user_expired_push.id
    user_expired_soon_push.id

    assert_equal 2, Push.count
    assert_equal 2, AuditLog.count

    CleanUpExpiredPushesAfterDurationJob.perform_now

    assert_equal 1, Push.count
    assert_nil Push.find_by(id: user_expired_id)

    assert_equal 1, AuditLog.count
  end

  test "job handles empty database gracefully" do
    assert_equal 0, Push.count
    assert_equal 0, AuditLog.count

    # Run the job - should not raise any errors
    assert_nothing_raised do
      CleanUpExpiredPushesAfterDurationJob.perform_now
    end
  end

  test "job does not delete any job if purge_after is 'disabled'" do
    Settings.purge_after = "disabled"

    user = users(:one)

    user_expired_push = Push.create!(
      kind: :text,
      payload: "test_payload",
      url_token: "user_expired",
      expired_on: Time.now - 20.days,
      expired: true,
      user_id: user.id
    )

    # Run the job - should not raise any errors
    assert_nothing_raised do
      CleanUpExpiredPushesAfterDurationJob.perform_now
    end

    assert_not_nil Push.find(user_expired_push.id)
  end

  test "job correctly logs the number of deleted pushes" do
    user = users(:one)

    # Create multiple expired pushes
    2.times do |i|
      push = Push.create!(
        kind: :text,
        payload: "test_payload_#{i}",
        url_token: "anonymous_expired_#{i}",
        expired_on: Time.now - 20.days,
        expired: true,
        user_id: user.id
      )

      AuditLog.create!(push: push, kind: :creation, ip: "127.0.0.1")
    end

    # Capture the log output
    Rails.logger
    begin
      log_output = StringIO.new
      logger = Logger.new(log_output)

      # Override the logger method
      CleanUpExpiredPushesAfterDurationJob.class_eval do
        define_method(:logger) do
          logger
        end
      end

      # Run the job
      CleanUpExpiredPushesAfterDurationJob.perform_now

      # Verify the log contains the correct count of deleted pushes
      log_output.rewind
      log_content = log_output.read
      assert_match(/2 total pushes expired more than 15 days ago were deleted./, log_content)
    ensure
      # Restore the original logger method
      CleanUpExpiredPushesAfterDurationJob.class_eval do
        remove_method :logger if method_defined?(:logger)
      end
    end
  end

  test "job processes all pushes expired more than purge_after ago" do
    user = users(:one)

    10.times do |i|
      push = Push.create!(
        kind: :text,
        payload: "test_payload_#{i}",
        url_token: "anonymous_expired_#{i}",
        expired_on: 20.days.ago,
        expired: true,
        user_id: user.id
      )
      AuditLog.create!(push: push, kind: :creation, ip: "127.0.0.1")
    end

    3.times do |i|
      push = Push.create!(
        kind: :text,
        payload: "test_payload_user_#{i}",
        url_token: "user_expired_#{i}",
        expired: true,
        expired_on: 10.days.ago,
        user_id: user.id
      )
      AuditLog.create!(push: push, kind: :creation, ip: "127.0.0.1")
    end

    CleanUpExpiredPushesAfterDurationJob.perform_now

    assert_equal 0, Push.where(expired: true).where("expired_on < ?", 15.days.ago).count
    assert_equal 3, Push.where(expired: true).count
  end
end
