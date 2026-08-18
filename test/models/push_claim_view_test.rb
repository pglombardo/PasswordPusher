# frozen_string_literal: true

require "test_helper"

class PushClaimViewTest < ActiveSupport::TestCase
  setup do
    @owner = users(:luca)
    @admin = users(:mr_admin)
  end

  test "claim_view! delivers payload and logs a counting view" do
    push = Push.create!(kind: "text", payload: "secret-payload", expire_after_views: 2, expire_after_days: 7)

    result = push.claim_view!(ip: "127.0.0.1", user_agent: "test", referrer: "")

    assert result.ok?
    assert_not result.expire_after_response
    assert_equal "secret-payload", result.payload
    assert_equal :view, result.kind
    assert_equal 1, push.reload.view_count
    assert_equal 1, push.views_remaining
    assert_not push.expired?
    assert_equal "secret-payload", push.payload
  end

  test "claim_view! flags expire_after_response on the last counting view" do
    push = Push.create!(kind: "text", payload: "one-time-secret", expire_after_views: 1, expire_after_days: 7)

    result = push.claim_view!(ip: "127.0.0.1")

    assert result.ok?
    assert result.expire_after_response
    assert_equal "one-time-secret", result.payload
    assert_equal 1, push.audit_logs.where(kind: :view).count

    # Caller expires after response (controllers do this)
    push.expire!
    push.reload
    assert push.expired?
    assert_nil push.payload
    assert_equal 0, push.views_remaining
  end

  test "claim_view! returns expired with nil payload when already exhausted" do
    push = Push.create!(kind: "text", payload: "gone", expire_after_views: 1, expire_after_days: 7)
    result = push.claim_view!(ip: "127.0.0.1")
    push.expire! if result.expire_after_response

    result = push.claim_view!(ip: "127.0.0.1")

    assert result.expired?
    assert_nil result.payload
    assert_equal :failed_view, result.kind
    assert_nil push.reload.payload
  end

  test "owner views do not burn view quota or expire the push" do
    push = Push.create!(
      kind: "text",
      payload: "owner-secret",
      expire_after_views: 1,
      expire_after_days: 7,
      user: @owner
    )

    result = push.claim_view!(viewer: @owner, ip: "127.0.0.1")

    assert result.ok?
    assert_equal :owner_view, result.kind
    assert_equal "owner-secret", result.payload

    push.reload
    assert_not push.expired?
    assert_equal 0, push.view_count
    assert_equal 1, push.views_remaining
    assert_equal 1, push.audit_logs.where(kind: :owner_view).count
  end

  test "admin views do not burn view quota" do
    push = Push.create!(
      kind: "text",
      payload: "admin-secret",
      expire_after_views: 1,
      expire_after_days: 7,
      user: @owner
    )

    result = push.claim_view!(viewer: @admin, admin: true, ip: "127.0.0.1")

    assert result.ok?
    assert_equal :admin_view, result.kind

    push.reload
    assert_not push.expired?
    assert_equal 0, push.view_count
    assert_equal 1, push.audit_logs.where(kind: :admin_view).count
  end

  test "claim_view! fails closed for counting views when audit log cap is reached" do
    push = Push.create!(kind: "text", payload: "capped-secret", expire_after_views: 5, expire_after_days: 7)
    push.audit_logs.create!(kind: :failed_passphrase, ip: "127.0.0.1")

    old_max = AuditLog::MAX_AUDIT_LOGS_PER_PUSH_OR_PULL
    silence_warnings { AuditLog.const_set(:MAX_AUDIT_LOGS_PER_PUSH_OR_PULL, 1) }

    result = push.claim_view!(ip: "127.0.0.1")

    assert result.expired?
    assert_nil result.payload
    assert_equal :view, result.kind
    assert_not result.expire_after_response
    assert push.reload.expired?
    assert_nil push.payload
    assert_equal 0, push.audit_logs.where(kind: :view).count
  ensure
    silence_warnings { AuditLog.const_set(:MAX_AUDIT_LOGS_PER_PUSH_OR_PULL, old_max) }
  end

  test "owner claim still delivers when audit log cap is reached" do
    push = Push.create!(
      kind: "text",
      payload: "owner-capped",
      expire_after_views: 1,
      expire_after_days: 7,
      user: @owner
    )
    push.audit_logs.create!(kind: :failed_passphrase, ip: "127.0.0.1")

    old_max = AuditLog::MAX_AUDIT_LOGS_PER_PUSH_OR_PULL
    silence_warnings { AuditLog.const_set(:MAX_AUDIT_LOGS_PER_PUSH_OR_PULL, 1) }

    result = push.claim_view!(viewer: @owner, ip: "127.0.0.1")

    assert result.ok?
    assert_equal "owner-capped", result.payload
    assert_equal :owner_view, result.kind
    assert_not push.reload.expired?
  ensure
    silence_warnings { AuditLog.const_set(:MAX_AUDIT_LOGS_PER_PUSH_OR_PULL, old_max) }
  end

  test "concurrent claim_view! allows only one successful delivery for a one-time push" do
    push = Push.create!(kind: "text", payload: "race-secret", expire_after_views: 1, expire_after_days: 7)
    push_id = push.id
    results = Queue.new
    thread_count = 8

    threads = thread_count.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          attempts = 0
          begin
            attempts += 1
            claimed = Push.find(push_id).claim_view!(ip: "127.0.0.1")
            Push.find(push_id).expire! if claimed.expire_after_response
            results << claimed
          rescue ActiveRecord::StatementInvalid, SQLite3::BusyException
            retry if attempts < 10
            raise
          end
        end
      end
    end

    threads.each(&:join)

    claimed = Array.new(thread_count) { results.pop }
    successful = claimed.select(&:ok?)
    expired = claimed.select(&:expired?)

    assert_equal 1, successful.size, "expected exactly one successful claim, got #{successful.size}"
    assert_equal ["race-secret"], successful.map(&:payload).uniq
    assert_equal thread_count - 1, expired.size
    assert_nil Push.find(push_id).payload
    assert Push.find(push_id).expired?
  end
end
