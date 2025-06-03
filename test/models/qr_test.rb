# frozen_string_literal: true

require "test_helper"

class QrTest < ActiveSupport::TestCase
  setup do
    @default_enable_qr_pushes = Settings.enable_qr_pushes
    @default_enable_logins = Settings.enable_logins

    Settings.enable_qr_pushes = true
    Settings.enable_logins = true
  end

  teardown do
    Settings.enable_qr_pushes = @default_enable_qr_pushes
    Settings.enable_logins = @default_enable_logins
  end

  test "should create QR code push with name" do
    qr = Push.new(
      kind: "qr",
      payload: "testqr",
      name: "Test QR Code"
    )
    assert qr.save
    assert_equal "Test QR Code", qr.name
  end

  test "should save QR Code push without name" do
    qr = Push.new(
      kind: "qr",
      payload: "testqr"
    )
    assert qr.save
    assert_equal "", qr.name
  end

  test "should include name in json representation when owner is true" do
    qr = Push.new(
      kind: "qr",
      payload: "testqr",
      name: "Test QR Code",
      expire_after_days: 7,
      expire_after_views: 10
    )
    assert qr.save

    json = JSON.parse(qr.to_json({owner: true}))
    assert_equal "Test QR Code", json["name"]
  end

  test "should not include name in json representation when owner is false" do
    qr = Push.new(
      kind: "qr",
      payload: "testqr",
      name: "Test QR Code",
      expire_after_days: 7,
      expire_after_views: 10
    )
    assert qr.save

    json = JSON.parse(qr.to_json({}))
    assert_not json.key?("name")
  end
end
