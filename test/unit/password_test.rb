require 'test_helper'

class PasswordTest < Minitest::Test
  def test_save
    password = Password.new
    password.validate!
    assert password.save
  end
end