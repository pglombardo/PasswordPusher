# frozen_string_literal: true

require "test_helper"

class PasswordTest < ActiveSupport::TestCase
  test "should create password with name" do
    password = Push.new(
      kind: "text",
      payload: "test_payload",
      name: "Test Password"
    )
    assert password.save
    assert_equal "Test Password", password.name
  end

  test "should save password without name" do
    password = Push.new(
      kind: "text",
      payload: "test_payload"
    )
    assert password.save
    assert_equal "", password.name
  end

  test "should include name in json representation when owner is true" do
    password = Push.new(
      kind: "text",
      payload: "test_payload",
      name: "Test Password",
      expire_after_days: 7,
      expire_after_views: 10
    )
    assert password.save

    json = JSON.parse(password.to_json({owner: true}))
    assert_equal "Test Password", json["name"]
  end

  test "should not include name in json representation when owner is false" do
    password = Push.new(
      kind: "text",
      payload: "test_payload",
      name: "Test Password",
      expire_after_days: 7,
      expire_after_views: 10
    )
    assert password.save

    json = JSON.parse(password.to_json({}))
    assert_not json.key?("name")
  end
end
