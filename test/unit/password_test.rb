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
end
