# frozen_string_literal: true

require "test_helper"

class PasswordUnitTest < Minitest::Test
  def test_save
    password = Push.create(kind: "text", payload: "asdf")
    password.check_limits
    assert password.save
  end

  def test_kind_validation
    password = Push.create(kind: "text", payload: "asdf")
    password.valid?
    assert password.errors[:kind].none?

    password.kind = "test_kind"
    password.valid?
    assert password.errors[:kind].any?

    password.kind = "text"
    password.valid?
    assert password.errors[:kind].none?

    password.kind = nil
    password.valid?
    assert password.errors[:kind].any?
  end

  def test_expired_check
    password = Push.create(kind: "text", payload: "asdf")
    password.check_limits
    assert_not password.expired?

    password = Push.create(kind: "text", payload: "asdf", created_at: 100.weeks.ago, updated_at: 100.weeks.ago)
    assert password

    password.check_limits
    assert password.expired?
  end

  def test_defaults
    push = Push.create(kind: "text", created_at: 3.days.ago, updated_at: 3.days.ago, payload: "asdf")

    assert push.expire_after_days == Settings.pw.expire_after_days_default
    assert push.expire_after_views == Settings.pw.expire_after_views_default

    assert push.retrieval_step == Settings.pw.retrieval_step_default
    assert push.deletable_by_viewer == Settings.pw.deletable_pushes_default
  end

  def test_days_expiration
    # 3 days left
    push = Push.create(kind: "text", created_at: 3.days.ago, updated_at: 3.days.ago,
      payload: "asdf", expire_after_days: 6)
    push.check_limits

    assert push.days_old == 3
    assert push.days_remaining == 3
    assert_not push.expired

    # already expired
    push = Push.create(kind: "text", created_at: 3.days.ago, updated_at: 3.days.ago,
      payload: "asdf", expire_after_days: 1)
    push.check_limits

    assert push.days_old == 3
    assert push.days_remaining.zero?
    assert push.expired

    # Old expired push
    push = Push.create(kind: "text", created_at: 100.days.ago, updated_at: 100.days.ago,
      payload: "asdf", expire_after_days: 1)
    push.check_limits

    assert push.days_old == 100
    assert push.days_remaining.zero?
    assert push.expired

    # Today 1 day password
    push = Push.create(kind: "text", payload: "asdf", expire_after_days: 1)
    push.check_limits

    assert push.days_old.zero?
    assert push.days_remaining == 1
    assert_not push.expired
  end

  def test_views_expiration
    # No views
    push = Push.create(kind: "text", payload: "asdf", expire_after_views: 1)
    push.check_limits

    assert push.views_remaining == 1
    assert_not push.expired

    # 1 View should expire
    push = Push.create(kind: "text", payload: "asdf", expire_after_views: 1)
    push.check_limits

    assert push.views_remaining == 1
    assert_not push.expired

    push.audit_logs.create(kind: :view)
    push.check_limits

    assert push.views_remaining.zero?
    assert push.expired
  end
end
