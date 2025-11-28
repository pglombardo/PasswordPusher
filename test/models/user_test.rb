# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @luca = users(:luca)
  end

  test "should have pushes" do
    Push.create(
      kind: "text",
      user: @luca,
      payload: "testpw"
    )

    assert_equal 1, @luca.pushes.count
  end

  test "can be admin" do
    assert_not @luca.admin?

    ActiveRecord::Base.connection.exec_update(
      "UPDATE users SET admin = ? WHERE id = ?",
      "Update User Admin Status",
      [true, @luca.id]
    )

    @luca.reload
    assert @luca.admin?
  end
end
