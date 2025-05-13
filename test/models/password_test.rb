# frozen_string_literal: true

require "test_helper"

class PasswordTest < ActiveSupport::TestCase
  test "should create password with name" do
    password = Password.new(
      payload: "test_payload",
      name: "Test Password"
    )
    assert password.save
    assert_equal "Test Password", password.name
  end

  test "should include name in json representation" do
    password = Password.new(
      payload: "test_payload",
      name: "Test Password",
      expire_after_days: 7,
      expire_after_views: 10
    )
    assert password.save

    json = JSON.parse(password.to_json({}))
    assert_equal "Test Password", json["name"]
  end

  test "should save password without name" do
    password = Password.new(
      payload: "test_payload"
    )
    assert password.save
    assert_nil password.name
  end

  test "should include name as nil in json representation" do
    password = Password.new(
      payload: "test_payload",
      expire_after_days: 7,
      expire_after_views: 10
    )
    assert password.save

    json = JSON.parse(password.to_json({}))
    assert_nil json["name"]
  end
end
