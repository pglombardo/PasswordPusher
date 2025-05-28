# frozen_string_literal: true

require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  include Devise::Test::IntegrationHelpers

  def setup
    # Create a push without using fixtures
    @push = Push.create!(
      kind: "text",
      payload: "test_payload",
      url_token: "testtoken123",
      expire_after_days: 7,
      expire_after_views: 5
    )

    # Create a user without using fixtures
    @luca = users(:luca)
  end

  test "should have valid kinds" do
    valid_kinds = [:creation, :view, :failed_view, :expire, :failed_passphrase]
    valid_kinds.each do |kind|
      audit_log = AuditLog.new(kind: kind, push: @push)
      assert audit_log.valid?, "#{kind} should be a valid kind"
    end
  end

  test "should not accept invalid kind" do
    audit_log = AuditLog.new(kind: :invalid_kind)
    assert_not audit_log.save
    assert_not audit_log.valid?, "invalid_kind should be a valid kind"
  end

  test "should belong to a push" do
    audit_log = AuditLog.new(kind: :view)
    assert_not audit_log.valid?
    assert_includes audit_log.errors.full_messages, "Push must exist"
  end

  test "user can be optional" do
    audit_log = AuditLog.new(kind: :view, push: @push)
    assert audit_log.valid?
    assert_nil audit_log.user
  end

  test "can belong to a user" do
    audit_log = AuditLog.new(kind: :view, push: @push, user: @luca)
    assert audit_log.valid?
    assert_equal @luca, audit_log.user
  end

  test "subject_name returns user email when user exists" do
    audit_log = AuditLog.new(kind: :view, push: @push, user: @luca)
    assert_equal @luca.email, audit_log.subject_name
  end

  test "subject_name returns '❓' when user does not exist" do
    audit_log = AuditLog.new(kind: :view, push: @push)
    assert_equal "❓", audit_log.subject_name
  end
end
