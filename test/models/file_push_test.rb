# frozen_string_literal: true

require "test_helper"
require "active_storage/engine"

class FilePushTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess

  setup do
    @user = users(:luca)
    Settings.enable_file_pushes = true
  end
  test "should create file push with name" do
    file_push = Push.new(
      kind: "file",
      name: "Test File Push",
      user: @user
    )
    file = fixture_file_upload("monkey.png", "image/jpeg")
    file_push.files.attach(file)

    assert file_push.save
    assert_equal "Test File Push", file_push.name
  end

  test "should save file push without name" do
    file_push = Push.new(
      kind: "file",
      user: @user
    )
    file = fixture_file_upload("monkey.png", "image/jpeg")
    file_push.files.attach(file)

    assert file_push.save
    assert_nil file_push.name
  end

  test "should include name in json representation when owner is true" do
    file_push = Push.new(
      kind: "file",
      name: "Test File Push",
      user: @user,
      expire_after_days: 7,
      expire_after_views: 10
    )
    file = fixture_file_upload("monkey.png", "image/jpeg")
    file_push.files.attach(file)

    assert file_push.save

    json = JSON.parse(file_push.to_json({owner: true}))
    assert_equal "Test File Push", json["name"]
  end

  test "should not include name in json representation when owner is false" do
    file_push = Push.new(
      kind: "file",
      name: "Test File Push",
      user: @user,
      expire_after_days: 7,
      expire_after_views: 10
    )
    file = fixture_file_upload("monkey.png", "image/jpeg")
    file_push.files.attach(file)

    assert file_push.save

    json = JSON.parse(file_push.to_json({}))
    assert_nil json["name"]
  end
end
