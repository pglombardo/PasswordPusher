# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @luca = users(:luca)
    travel_to Time.current.beginning_of_day + 6.hours
  end

  teardown do
    travel_back
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

  test "email_limit_reached? returns true when email_sent_count is greater than or equal to 100" do
    @luca.update(email_sent_count: 100, email_sent_count_reset_at: Time.current)

    assert @luca.email_limit_reached?
  end

  test "email_limit_reached? returns false when email_sent_count is less than 100" do
    @luca.update(email_sent_count: 99, email_sent_count_reset_at: Time.current)

    refute @luca.email_limit_reached?
  end

  test "email_limit_reached? returns false when email_sent_count_reset_at is before the beginning of the day" do
    @luca.update(email_sent_count: 100, email_sent_count_reset_at: 2.day.ago)

    refute @luca.email_limit_reached?
  end
end
