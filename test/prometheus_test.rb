# frozen_string_literal: true

require "test_helper"

class PrometheusTest < ActiveSupport::TestCase
  # PrometheusMetrics Concern Tests

  test "track_metric does nothing in test environment" do
    # Metrics are disabled in test environment
    assert_nothing_raised do
      PrometheusMetrics.track_metric("test_action", {test_label: "test_value"})
    end
  end

  # Push Tests
  test "push creation does not break application" do
    push = Push.create!(
      kind: "text",
      payload: "test_payload",
      deletable_by_viewer: true,
      retrieval_step: false
    )

    assert push.persisted?
    assert_equal "text", push.kind
  end

  test "push with passphrase does not break application" do
    push = Push.create!(
      kind: "text",
      payload: "test_payload",
      passphrase: "secret123",
      deletable_by_viewer: true,
      retrieval_step: false
    )

    assert push.persisted?
    assert push.passphrase.present?
  end

  test "push by authenticated user does not break application" do
    user = users(:luca)

    push = Push.create!(
      kind: "text",
      payload: "test_payload",
      user: user,
      deletable_by_viewer: true,
      retrieval_step: false
    )

    assert push.persisted?
    assert_equal user.id, push.user_id
  end

  test "push expiration does not break application" do
    push = Push.create!(
      kind: "text",
      payload: "test_payload",
      deletable_by_viewer: true,
      retrieval_step: false,
      expired: false
    )

    push.update!(expired: true)

    assert push.expired?
  end

  # AuditLog Tests
  test "audit log view does not break application" do
    push = Push.create!(
      kind: "text",
      payload: "test_payload",
      deletable_by_viewer: true,
      retrieval_step: false
    )

    audit_log = AuditLog.create!(kind: :view, push: push)

    assert audit_log.persisted?
    assert_equal "view", audit_log.kind
  end

  test "audit log failed_view does not break application" do
    push = Push.create!(kind: "text", payload: "test", deletable_by_viewer: true, retrieval_step: false)
    audit_log = AuditLog.create!(kind: :failed_view, push: push)

    assert audit_log.persisted?
    assert_equal "failed_view", audit_log.kind
  end

  test "audit log failed_passphrase does not break application" do
    push = Push.create!(kind: "text", payload: "test", deletable_by_viewer: true, retrieval_step: false)
    audit_log = AuditLog.create!(kind: :failed_passphrase, push: push)

    assert audit_log.persisted?
    assert_equal "failed_passphrase", audit_log.kind
  end

  test "audit log admin_view does not break application" do
    push = Push.create!(kind: "text", payload: "test", deletable_by_viewer: true, retrieval_step: false)
    audit_log = AuditLog.create!(kind: :admin_view, push: push)

    assert audit_log.persisted?
    assert_equal "admin_view", audit_log.kind
  end

  test "audit log owner_view does not break application" do
    push = Push.create!(kind: "text", payload: "test", deletable_by_viewer: true, retrieval_step: false)
    audit_log = AuditLog.create!(kind: :owner_view, push: push)

    assert audit_log.persisted?
    assert_equal "owner_view", audit_log.kind
  end

  # User Tests
  test "user signup does not break application" do
    user = User.new(
      email: "test@example.com",
      password: "SecurePassword123!",
      password_confirmation: "SecurePassword123!"
    )
    user.skip_confirmation!

    assert user.save
    assert_equal "test@example.com", user.email
  end

  test "user signup with preferred language does not break application" do
    user = User.new(
      email: "test-fr@example.com",
      password: "SecurePassword123!",
      password_confirmation: "SecurePassword123!",
      preferred_language: "fr"
    )
    user.skip_confirmation!

    assert user.save
    assert_equal "fr", user.preferred_language
  end

  test "user account lockout does not break application" do
    user = users(:luca)

    user.update!(locked_at: Time.current)

    assert user.locked_at.present?
    assert user.access_locked?
  end

  # Model Integration Tests
  test "Push model includes PrometheusMetrics concern" do
    assert Push.included_modules.include?(PrometheusMetrics)
  end

  test "AuditLog model includes PrometheusMetrics concern" do
    assert AuditLog.included_modules.include?(PrometheusMetrics)
  end

  test "User model includes PrometheusMetrics concern" do
    assert User.included_modules.include?(PrometheusMetrics)
  end
end
