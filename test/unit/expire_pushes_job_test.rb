# frozen_string_literal: true

require "test_helper"

class ExpirePushesJobTest < ActiveSupport::TestCase
  setup do
    # Clear all pushes before running tests
    AuditLog.delete_all
    Push.delete_all
    User.delete_all

    # Set default URL options for test environment to avoid missing host errors
    Rails.application.routes.default_url_options[:host] = "localhost:3000"

    # Freeze time for predictable testing
    travel_to Time.zone.local(2025, 5, 26)
  end

  teardown do
    # Unfreeze time
    travel_back
  end

  test "job expires pushes that have reached their expiration limits" do
    # Create pushes that should expire due to days limit
    expired_by_days = create_push(expire_after_days: 1, created_at: 2.days.ago)

    # Create pushes that should expire due to views limit
    expired_by_views = create_push(expire_after_views: 3)
    create_views_for_push(expired_by_views, 3) # Create 3 views, reaching the limit

    # Create a push that should not expire (within limits)
    active_push = create_push(expire_after_days: 7, expire_after_views: 5)
    create_views_for_push(active_push, 2) # Only 2 views, below the limit

    # Run the job
    ExpirePushesJob.perform_now

    # Reload the pushes from the database
    expired_by_days.reload
    expired_by_views.reload
    active_push.reload

    # Verify pushes were expired correctly
    assert expired_by_days.expired, "Push should be expired due to days limit"
    assert expired_by_views.expired, "Push should be expired due to views limit"
    assert_not active_push.expired, "Push should still be active"

    # Verify content was cleared for expired pushes
    assert_nil expired_by_days.payload
    assert_nil expired_by_views.payload
    assert_not_nil active_push.payload
  end

  test "job correctly counts and logs expired pushes" do
    # Create several pushes that should expire
    3.times do |i|
      create_push(expire_after_days: 1, created_at: 2.days.ago)
    end

    # Create several pushes that should not expire
    2.times do |i|
      create_push
    end

    # Store the original method to restore it later
    original_logger_method = nil
    if ExpirePushesJob.method_defined?(:logger)
      original_logger_method = ExpirePushesJob.instance_method(:logger)
    end

    begin
      # Capture the log output
      log_output = StringIO.new
      test_logger = Logger.new(log_output)

      # Override the logger method
      ExpirePushesJob.class_eval do
        define_method(:logger) do
          test_logger
        end
      end

      # Run the job
      ExpirePushesJob.perform_now

      # Verify the log contains the correct counts
      log_output.rewind
      log_content = log_output.read

      assert_match(/Finished validating 5 unexpired pushes/, log_content)
      assert_match(/3 total pushes expired/, log_content)
    ensure
      # Properly restore the original logger method
      ExpirePushesJob.class_eval do
        remove_method :logger if method_defined?(:logger)

        # If there was an original method, restore it
        if original_logger_method
          define_method(:logger, original_logger_method)
        end
      end
    end
  end

  test "job processes all unexpired pushes" do
    # Create a large number of unexpired pushes with mixed expiration states
    5.times { |i| create_push(expire_after_days: 1, created_at: 2.days.ago, url_token: "should_expire_#{i}") }
    5.times { |i| create_push(url_token: "should_not_expire_#{i}") }

    # Verify initial state
    assert_equal 10, Push.where(expired: false).count
    assert_equal 0, Push.where(expired: true).count

    # Run the job
    ExpirePushesJob.perform_now

    # Verify the correct pushes were expired
    assert_equal 5, Push.where(expired: false).count
    assert_equal 5, Push.where(expired: true).count
  end

  test "job handles both anonymous and user-owned pushes" do
    # Create a user
    user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.now
    )

    # Create anonymous pushes that should expire
    anon_expired = create_push(expire_after_days: 1, created_at: 2.days.ago)

    # Create user-owned pushes that should expire
    user_expired = create_push(
      expire_after_days: 1,
      created_at: 2.days.ago,
      user_id: user.id
    )

    # Run the job
    ExpirePushesJob.perform_now

    # Verify both types of pushes were expired
    anon_expired.reload
    user_expired.reload

    assert anon_expired.expired
    assert user_expired.expired

    # Verify content was cleared for both
    assert_nil anon_expired.payload
    assert_nil user_expired.payload
  end

  test "job handles empty database gracefully" do
    # Ensure no pushes exist
    Push.delete_all
    assert_equal 0, Push.count

    # Run the job - should not raise any errors
    assert_nothing_raised do
      ExpirePushesJob.perform_now
    end
  end

  private

  # Helper method to create a push with default values
  def create_push(options = {})
    defaults = {
      kind: :text,
      payload: "test_payload",
      user_id: nil,
      created_at: Time.current
    }

    push = Push.create!(defaults.merge(options))
    AuditLog.create!(push: push, kind: :creation, ip: "127.0.0.1")
    push
  end

  # Helper method to create views for a push
  def create_views_for_push(push, count)
    count.times do
      AuditLog.create!(push: push, kind: :view, ip: "127.0.0.1")
    end
  end
end
