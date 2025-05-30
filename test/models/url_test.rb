# frozen_string_literal: true

require "test_helper"

class UrlTest < ActiveSupport::TestCase
  setup do
    @default_enable_url_pushes = Settings.enable_url_pushes
    @default_enable_logins = Settings.enable_logins

    Settings.enable_url_pushes = true
    Settings.enable_logins = true
  end

  teardown do
    Settings.enable_url_pushes = @default_enable_url_pushes
    Settings.enable_logins = @default_enable_logins
  end

  test "should create url with name" do
    url = Push.new(
      kind: "url",
      payload: "https://example.com",
      name: "Test URL"
    )
    assert url.save
    assert_equal "Test URL", url.name
  end

  test "should save url without name" do
    url = Push.new(
      kind: "url",
      payload: "https://example.com"
    )
    assert url.save
    assert_equal "", url.name
  end

  test "should include name in json representation when owner is true" do
    url = Push.new(
      kind: "url",
      payload: "https://example.com",
      name: "Test URL",
      expire_after_days: 7,
      expire_after_views: 10
    )
    assert url.save

    json = JSON.parse(url.to_json({owner: true}))
    assert_equal "Test URL", json["name"]
  end

  test "should not include name in json representation when owner is false" do
    url = Push.new(
      kind: "url",
      payload: "https://example.com",
      name: "Test URL",
      expire_after_days: 7,
      expire_after_views: 10
    )
    assert url.save

    json = JSON.parse(url.to_json({}))
    assert_not json.key?("name")
  end
end
