require 'test_helper'

class PasswordTest < Minitest::Test
  def test_save
    password = Password.new
    password.validate!
    assert password.save
  end

  def test_expired_check
    password = Password.new(payload: 'asdf')
    password.validate!
    assert !password.expired?
    assert password.save
    assert !password.expired?
    password.validate!
    assert !password.expired?

    password = Password.new(created_at: 100.week.ago, updated_at: 100.week.ago)
    password.validate!
    # New records don't get expiration check
    assert !password.expired?
    assert password.save

    # Saved/pre-existing record gets check for expiration
    password.validate!
    assert password.expired?
  end

  def test_defaults
    push = Password.new(created_at: 3.days.ago, updated_at: 3.days.ago, payload: 'asdf')
    push.validate!

    assert push.expire_after_days == EXPIRE_AFTER_DAYS_DEFAULT
    assert push.expire_after_views == EXPIRE_AFTER_VIEWS_DEFAULT

    assert push.retrieval_step == RETRIEVAL_STEP_DEFAULT if RETRIEVAL_STEP_ENABLED
    assert push.deletable_by_viewer == DELETABLE_PASSWORDS_DEFAULT if DELETABLE_PASSWORDS_ENABLED
  end

  def test_days_expiration
    # 3 days left
    push = Password.new(created_at: 3.days.ago, updated_at: 3.days.ago,
                        payload: 'asdf', expire_after_days: 6)
    push.save
    push.validate!

    assert push.days_old == 3
    assert push.days_remaining == 3
    assert !push.expired

    # already expired
    push = Password.new(created_at: 3.days.ago, updated_at: 3.days.ago,
                        payload: 'asdf', expire_after_days: 1)
    push.save
    push.validate!

    assert push.days_old == 3
    assert push.days_remaining.zero?
    assert push.expired

    # Old expired expired
    push = Password.new(created_at: 100.days.ago, updated_at: 100.days.ago,
                        payload: 'asdf', expire_after_days: 1)
    push.save
    push.validate!

    assert push.days_old == 100
    assert push.days_remaining.zero?
    assert push.expired

    # Today 1 day password
    push = Password.new(payload: 'asdf', expire_after_days: 1)
    push.save
    push.validate!

    assert push.days_old.zero?
    assert push.days_remaining == 1
    assert !push.expired
  end

  def test_views_expiration
    # No views
    push = Password.new(payload: 'asdf', expire_after_views: 1)
    push.save
    push.validate!

    assert push.views_remaining == 1
    assert !push.expired

    # 1 View should expire
    push = Password.new(payload: 'asdf', expire_after_views: 1)
    push.save
    push.validate!

    view = View.new
    view.kind = 0 # standard user view
    view.password_id = push.id
    view.successful  = true
    view.save
    push.views << view

    push.validate!

    assert push.views_remaining.zero?
    assert push.expired
  end
end
