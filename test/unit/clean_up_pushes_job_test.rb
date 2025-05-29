# frozen_string_literal: true

require "test_helper"

class CleanUpPushesJobTest < ActiveSupport::TestCase
  setup do
    # Clear all pushes before running tests
    AuditLog.delete_all
    Push.delete_all
    User.delete_all

    # Set default URL options for test environment to avoid missing host errors
    Rails.application.routes.default_url_options[:host] = "localhost:3000"
  end

  test "job deletes anonymous expired pushes" do
    # Create an anonymous expired push
    anonymous_expired_push = Push.create!(
      kind: :text,
      payload: "test_payload",
      url_token: "anonymous_expired",
      expired: true,
      user_id: nil
    )

    # Create an audit log for the push
    AuditLog.create!(push: anonymous_expired_push, kind: :creation, ip: "127.0.0.1")

    # Create an anonymous non-expired push (should not be deleted)
    anonymous_active_push = Push.create!(
      kind: :text,
      payload: "test_payload",
      url_token: "anonymous_active",
      expired: false,
      user_id: nil
    )

    # Create an audit log for the push
    AuditLog.create!(push: anonymous_active_push, kind: :creation, ip: "127.0.0.1")

    # Create a user-owned expired push (should not be deleted)
    user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.now # Skip confirmation email requirements
    )

    user_expired_push = Push.create!(
      kind: :text,
      payload: "test_payload",
      url_token: "user_expired",
      expired: true,
      user_id: user.id
    )

    # Create an audit log for the push
    AuditLog.create!(push: user_expired_push, kind: :creation, ip: "127.0.0.1")

    # Store the IDs for later verification
    anonymous_expired_id = anonymous_expired_push.id
    anonymous_active_id = anonymous_active_push.id
    user_expired_id = user_expired_push.id

    # Count pushes before running the job
    pushes_before = Push.count
    assert_equal 3, pushes_before

    # Run the job
    CleanUpPushesJob.perform_now

    # Verify only the anonymous expired push was deleted
    assert_equal 2, Push.count
    assert_nil Push.find_by(id: anonymous_expired_id)
    assert_not_nil Push.find_by(id: anonymous_active_id)
    assert_not_nil Push.find_by(id: user_expired_id)

    # Verify audit logs were also deleted for the anonymous expired push
    assert_equal 0, AuditLog.where(push_id: anonymous_expired_id).count
  end

  test "job handles empty database gracefully" do
    # Ensure no pushes exist
    Push.delete_all
    assert_equal 0, Push.count

    # Run the job - should not raise any errors
    assert_nothing_raised do
      CleanUpPushesJob.perform_now
    end
  end

  test "job correctly logs the number of deleted pushes" do
    # Create multiple anonymous expired pushes
    5.times do |i|
      push = Push.create!(
        kind: :text,
        payload: "test_payload_#{i}",
        url_token: "anonymous_expired_#{i}",
        expired: true,
        user_id: nil
      )
      AuditLog.create!(push: push, kind: :creation, ip: "127.0.0.1")
    end

    # Capture the log output
    Rails.logger
    begin
      log_output = StringIO.new
      logger = Logger.new(log_output)

      # Override the logger method
      CleanUpPushesJob.class_eval do
        define_method(:logger) do
          logger
        end
      end

      # Run the job
      CleanUpPushesJob.perform_now

      # Verify the log contains the correct count of deleted pushes
      log_output.rewind
      log_content = log_output.read
      assert_match(/5 total anonymous expired pushes deleted/, log_content)
    ensure
      # Restore the original logger method
      CleanUpPushesJob.class_eval do
        remove_method :logger if method_defined?(:logger)
      end
    end
  end

  test "job processes all anonymous expired pushes" do
    # Create a large number of anonymous expired pushes
    10.times do |i|
      push = Push.create!(
        kind: :text,
        payload: "test_payload_#{i}",
        url_token: "anonymous_expired_#{i}",
        expired: true,
        user_id: nil
      )
      AuditLog.create!(push: push, kind: :creation, ip: "127.0.0.1")
    end

    # Create some non-anonymous expired pushes (should not be deleted)
    user = User.create!(
      email: "test2@example.com",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.now # Skip confirmation email requirements
    )

    3.times do |i|
      push = Push.create!(
        kind: :text,
        payload: "test_payload_user_#{i}",
        url_token: "user_expired_#{i}",
        expired: true,
        user_id: user.id
      )
      AuditLog.create!(push: push, kind: :creation, ip: "127.0.0.1")
    end

    # Run the job
    CleanUpPushesJob.perform_now

    # Verify all anonymous expired pushes were deleted
    assert_equal 0, Push.where(expired: true, user_id: nil).count
    assert_equal 3, Push.where(expired: true).count # Only user pushes remain
  end

  test "job works with multiple text pushes" do
    # Create multiple anonymous expired text pushes
    # Note: File and URL pushes seem to be disabled in the test environment
    3.times do |i|
      push = Push.create!(
        kind: :text,
        payload: "test_payload_#{i}",
        url_token: "anonymous_expired_#{i}",
        expired: true,
        user_id: nil
      )
      AuditLog.create!(push: push, kind: :creation, ip: "127.0.0.1")
    end

    assert_equal 3, Push.count

    # Run the job
    CleanUpPushesJob.perform_now

    # Verify all anonymous expired pushes were deleted
    assert_equal 0, Push.count
  end
end
