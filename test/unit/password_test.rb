# frozen_string_literal: true

require "test_helper"

class PasswordTest < Minitest::Test
  def test_save
    password = Password.new
    password.validate!
    assert password.save
  end

  def test_expired_check
    password = Password.new(payload: "asdf")
    password.validate!
    assert_not password.expired?
    assert password.save
    assert_not password.expired?
    password.validate!
    assert_not password.expired?

    password = Password.new(created_at: 100.weeks.ago, updated_at: 100.weeks.ago)
    password.validate!
    # New records don't get expiration check
    assert_not password.expired?
    assert password.save

    # Saved/pre-existing record gets check for expiration
    password.validate!
    assert password.expired?
  end

  def test_defaults
    push = Password.new(created_at: 3.days.ago, updated_at: 3.days.ago, payload: "asdf")
    push.validate!

    assert push.expire_after_days == Settings.pw.expire_after_days_default
    assert push.expire_after_views == Settings.pw.expire_after_views_default

    assert push.retrieval_step == Settings.pw.retrieval_step_default if Settings.pw.enable_retrieval_step
    assert push.deletable_by_viewer == Settings.pw.deletable_pushes_default if Settings.pw.enable_deletable_pushes
  end

  def test_days_expiration
    # 3 days left
    push = Password.new(created_at: 3.days.ago, updated_at: 3.days.ago,
      payload: "asdf", expire_after_days: 6)
    push.save
    push.validate!

    assert push.days_old == 3
    assert push.days_remaining == 3
    assert_not push.expired

    # already expired
    push = Password.new(created_at: 3.days.ago, updated_at: 3.days.ago,
      payload: "asdf", expire_after_days: 1)
    push.save
    push.validate!

    assert push.days_old == 3
    assert push.days_remaining.zero?
    assert push.expired

    # Old expired expired
    push = Password.new(created_at: 100.days.ago, updated_at: 100.days.ago,
      payload: "asdf", expire_after_days: 1)
    push.save
    push.validate!

    assert push.days_old == 100
    assert push.days_remaining.zero?
    assert push.expired

    # Today 1 day password
    push = Password.new(payload: "asdf", expire_after_days: 1)
    push.save
    push.validate!

    assert push.days_old.zero?
    assert push.days_remaining == 1
    assert_not push.expired
  end

  def test_views_expiration
    # No views
    push = Password.new(payload: "asdf", expire_after_views: 1)
    push.save
    push.validate!

    assert push.views_remaining == 1
    assert_not push.expired

    # 1 View should expire
    push = Password.new(payload: "asdf", expire_after_views: 1)
    push.save
    push.validate!

    view = View.new
    view.kind = 0 # standard user view
    view.password_id = push.id
    view.successful = true
    view.save
    push.views << view

    push.validate!

    assert push.views_remaining.zero?
    assert push.expired
  end
end
