# frozen_string_literal: true

require "test_helper"

# Create a test controller that includes LogEvents
class LogEventsTestController < ApplicationController
  include LogEvents
end

class LogEventsTest < ActionController::TestCase
  tests LogEventsTestController
  include Devise::Test::ControllerHelpers

  setup do
    @push = pushes(:test_push)
    @user = users(:luca)
    @user.confirm
    AuditLog.delete_all
  end

  # Test log_view method
  test "log_view creates view audit log for non-expired push" do
    @push.update(expired: false)

    @request.env["REMOTE_ADDR"] = "192.168.1.1"
    @request.env["HTTP_USER_AGENT"] = "Mozilla/5.0"
    @request.env["HTTP_REFERER"] = "https://example.com"

    result = @controller.log_view(@push)

    assert_equal @push, result
    assert_equal 1, AuditLog.count
    log = AuditLog.last
    assert_equal :view, log.kind.to_sym
    assert_equal @push, log.push
    assert_nil log.user
    assert_equal "192.168.1.1", log.ip
    assert_equal "Mozilla/5.0", log.user_agent
    assert_equal "https://example.com", log.referrer
  end

  test "log_view creates failed_view audit log for expired push" do
    @push.update(expired: true)

    @request.env["REMOTE_ADDR"] = "10.0.0.1"

    @controller.log_view(@push)

    assert_equal 1, AuditLog.count
    log = AuditLog.last
    assert_equal :failed_view, log.kind.to_sym
    assert_equal @push, log.push
  end

  test "log_view returns the push object" do
    @push.update(expired: false)
    @request.env["REMOTE_ADDR"] = "127.0.0.1"

    result = @controller.log_view(@push)
    assert_equal @push, result
  end

  test "log_view creates owner_view audit log when current_user is push owner" do
    @push.update(expired: false, user: @user)
    sign_in @user

    @request.env["REMOTE_ADDR"] = "192.168.1.1"
    @request.env["HTTP_USER_AGENT"] = "Mozilla/5.0"
    @request.env["HTTP_REFERER"] = "https://example.com"

    result = @controller.log_view(@push)

    assert_equal @push, result
    assert_equal 1, AuditLog.count
    log = AuditLog.last
    assert_equal :owner_view, log.kind.to_sym
    assert_equal @push, log.push
    assert_equal @user, log.user
    assert_equal "192.168.1.1", log.ip
    assert_equal "Mozilla/5.0", log.user_agent
    assert_equal "https://example.com", log.referrer
  end

  test "log_view creates admin_view audit log when current_user is admin but not owner" do
    admin = users(:mr_admin)
    @push.update(expired: false, user: @user)
    sign_in admin

    @request.env["REMOTE_ADDR"] = "10.0.0.5"
    @request.env["HTTP_USER_AGENT"] = "AdminBrowser/1.0"
    @request.env["HTTP_REFERER"] = "https://admin.com"

    result = @controller.log_view(@push)

    assert_equal @push, result
    assert_equal 1, AuditLog.count
    log = AuditLog.last
    assert_equal :admin_view, log.kind.to_sym
    assert_equal @push, log.push
    assert_equal admin, log.user
    assert_equal "10.0.0.5", log.ip
    assert_equal "AdminBrowser/1.0", log.user_agent
    assert_equal "https://admin.com", log.referrer
  end

  test "log_view creates regular view audit log when signed in user is neither owner nor admin" do
    other_user = users(:one)
    @push.update(expired: false, user: @user)
    sign_in other_user

    @request.env["REMOTE_ADDR"] = "172.16.0.10"
    @request.env["HTTP_USER_AGENT"] = "UserBrowser/2.0"
    @request.env["HTTP_REFERER"] = "https://user.com"

    result = @controller.log_view(@push)

    assert_equal @push, result
    assert_equal 1, AuditLog.count
    log = AuditLog.last
    assert_equal :view, log.kind.to_sym
    assert_equal @push, log.push
    assert_equal other_user, log.user
    assert_equal "172.16.0.10", log.ip
    assert_equal "UserBrowser/2.0", log.user_agent
    assert_equal "https://user.com", log.referrer
  end

  # Test log_creation method
  test "log_creation creates creation audit log" do
    @request.env["REMOTE_ADDR"] = "172.16.0.1"
    @request.env["HTTP_USER_AGENT"] = "TestAgent/1.0"
    @request.env["HTTP_REFERER"] = "https://test.com"

    @controller.log_creation(@push)

    assert_equal 1, AuditLog.count
    log = AuditLog.last
    assert_equal :creation, log.kind.to_sym
    assert_equal @push, log.push
    assert_equal "172.16.0.1", log.ip
    assert_equal "TestAgent/1.0", log.user_agent
    assert_equal "https://test.com", log.referrer
  end

  test "log_creation uses the push parameter" do
    @request.env["REMOTE_ADDR"] = "127.0.0.1"

    # log_creation now correctly uses the parameter passed to it
    other_push = Push.create!(
      kind: "text",
      payload: "other",
      url_token: "other_token",
      expire_after_days: 7,
      expire_after_views: 5
    )
    @controller.log_creation(other_push)

    assert_equal 1, AuditLog.count
    log = AuditLog.last
    # It logs the push parameter, not @push
    assert_equal other_push, log.push
    assert_not_equal @push, log.push
  end

  # Test log_failed_passphrase method
  test "log_failed_passphrase creates failed_passphrase audit log" do
    @request.env["REMOTE_ADDR"] = "192.168.0.1"
    @request.env["HTTP_USER_AGENT"] = "Browser/2.0"
    @request.env["HTTP_REFERER"] = "https://referrer.com"

    @controller.log_failed_passphrase(@push)

    assert_equal 1, AuditLog.count
    log = AuditLog.last
    assert_equal :failed_passphrase, log.kind.to_sym
    assert_equal @push, log.push
    assert_equal "192.168.0.1", log.ip
    assert_equal "Browser/2.0", log.user_agent
    assert_equal "https://referrer.com", log.referrer
  end

  # Test log_expire method
  test "log_expire creates expire audit log" do
    @request.env["REMOTE_ADDR"] = "203.0.113.1"
    @request.env["HTTP_USER_AGENT"] = "ExpireAgent/1.0"
    @request.env["HTTP_REFERER"] = "https://expire.com"

    @controller.log_expire(@push)

    assert_equal 1, AuditLog.count
    log = AuditLog.last
    assert_equal :expire, log.kind.to_sym
    assert_equal @push, log.push
    assert_equal "203.0.113.1", log.ip
    assert_equal "ExpireAgent/1.0", log.user_agent
    assert_equal "https://expire.com", log.referrer
  end

  # Test log_event method - IP address handling
  test "log_event uses HTTP_X_FORWARDED_FOR when present" do
    @request.env["HTTP_X_FORWARDED_FOR"] = "203.0.113.50, 192.168.1.1"
    @request.env["REMOTE_ADDR"] = "10.0.0.1"

    @controller.log_view(@push)

    log = AuditLog.last
    assert_equal "203.0.113.50, 192.168.1.1", log.ip
  end

  test "log_event uses REMOTE_ADDR when HTTP_X_FORWARDED_FOR is nil" do
    @request.env["REMOTE_ADDR"] = "10.0.0.2"

    @controller.log_view(@push)

    log = AuditLog.last
    assert_equal "10.0.0.2", log.ip
  end

  test "log_event uses REMOTE_ADDR when HTTP_X_FORWARDED_FOR is empty" do
    @request.env["HTTP_X_FORWARDED_FOR"] = ""
    @request.env["REMOTE_ADDR"] = "10.0.0.3"

    @controller.log_view(@push)

    log = AuditLog.last
    # Now correctly falls back to REMOTE_ADDR when HTTP_X_FORWARDED_FOR is empty
    assert_equal "10.0.0.3", log.ip
  end

  # Test user_agent truncation
  test "log_event truncates user_agent to 255 characters" do
    long_user_agent = "A" * 300
    @request.env["HTTP_USER_AGENT"] = long_user_agent
    @request.env["REMOTE_ADDR"] = "127.0.0.1"

    @controller.log_view(@push)

    log = AuditLog.last
    assert_equal 255, log.user_agent.length
    assert_equal "A" * 255, log.user_agent
  end

  test "log_event handles nil user_agent" do
    @request.env["REMOTE_ADDR"] = "127.0.0.1"
    @request.env["HTTP_USER_AGENT"] = nil

    @controller.log_view(@push)

    log = AuditLog.last
    # Rails test environment may set a default user agent, so we just verify it's a string
    assert_kind_of String, log.user_agent
  end

  # Test referrer truncation
  test "log_event truncates referrer to 255 characters" do
    long_referrer = "B" * 300
    @request.env["HTTP_REFERER"] = long_referrer
    @request.env["REMOTE_ADDR"] = "127.0.0.1"

    @controller.log_view(@push)

    log = AuditLog.last
    assert_equal 255, log.referrer.length
    assert_equal "B" * 255, log.referrer
  end

  test "log_event handles nil referrer" do
    @request.env["REMOTE_ADDR"] = "127.0.0.1"

    @controller.log_view(@push)

    log = AuditLog.last
    assert_equal "", log.referrer
  end

  # Test with authenticated user
  test "log_event associates audit log with current_user when signed in" do
    sign_in @user
    @request.env["REMOTE_ADDR"] = "127.0.0.1"

    @controller.log_view(@push)

    log = AuditLog.last
    assert_equal @user, log.user
  end

  test "log_event sets user to nil when not signed in" do
    @request.env["REMOTE_ADDR"] = "127.0.0.1"

    @controller.log_view(@push)

    log = AuditLog.last
    assert_nil log.user
  end

  # Test multiple audit logs
  test "can create multiple audit logs for same push" do
    @request.env["REMOTE_ADDR"] = "127.0.0.1"
    @controller.log_view(@push)

    @request.env["REMOTE_ADDR"] = "127.0.0.2"
    @controller.log_view(@push)

    @request.env["REMOTE_ADDR"] = "127.0.0.3"
    @controller.log_failed_passphrase(@push)

    assert_equal 3, AuditLog.count
    assert_equal 3, @push.audit_logs.count
    # Order doesn't matter, just verify all kinds are present
    assert_equal ["failed_passphrase", "view", "view"], AuditLog.pluck(:kind).sort
  end

  # Test edge cases
  test "log_event handles all valid audit log kinds" do
    kinds = [:creation, :view, :failed_view, :expire, :failed_passphrase, :owner_view, :admin_view]

    kinds.each do |kind|
      AuditLog.delete_all
      push = Push.create!(
        kind: "text",
        payload: "test",
        url_token: "token_#{kind}",
        expire_after_days: 7,
        expire_after_views: 5
      )

      @request.env["REMOTE_ADDR"] = "127.0.0.1"

      # Use the actual controller methods
      case kind
      when :view
        @controller.log_view(push)
      when :creation
        @controller.log_creation(push)
      when :failed_passphrase
        @controller.log_failed_passphrase(push)
      when :expire
        @controller.log_expire(push)
      when :failed_view
        push.update(expired: true)
        @controller.log_view(push)
      when :owner_view
        owner = users(:luca)
        push.update(user: owner)
        sign_in owner
        @controller.log_view(push)
        sign_out owner
      when :admin_view
        admin = users(:mr_admin)
        push.update(user: users(:one))
        sign_in admin
        @controller.log_view(push)
        sign_out admin
      end

      assert_equal 1, AuditLog.count, "Expected 1 audit log for kind: #{kind}"
      assert_equal kind.to_s, AuditLog.last.kind, "Expected kind #{kind} but got #{AuditLog.last.kind}"
    end
  end
end
