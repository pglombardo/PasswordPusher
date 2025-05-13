# frozen_string_literal: true

require "test_helper"

class FilePushTest < ActiveSupport::TestCase
  setup do
    @user = users(:luca)
  end
  test "should create file push with name" do
    file_push = FilePush.new(
      payload: "test payload",
      name: "Test File Push",
      user: @user
    )
    assert file_push.save
    assert_equal "Test File Push", file_push.name
  end

  test "should save file push without name" do
    file_push = FilePush.new(
      payload: "test payload",
      user: @user
    )
    assert file_push.save
    assert_nil file_push.name
  end
  
  test "should include name in json representation" do
    file_push = FilePush.new(
      payload: "test payload",
      name: "Test File Push",
      user: @user,
      expire_after_days: 7,
      expire_after_views: 10
    )
    assert file_push.save
    
    json = JSON.parse(file_push.to_json({}))
    assert_equal "Test File Push", json["name"]
  end
end
