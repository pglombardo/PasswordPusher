# frozen_string_literal: true

require "test_helper"

class PushEditTest < ActiveSupport::TestCase
  setup do
    @user = users(:luca)
  end

  test "should update text push with valid payload" do
    push = Push.create!(
      kind: "text",
      payload: "Original password",
      user: @user
    )

    push.payload = "Updated password"
    assert push.save
    assert_equal "Updated password", push.payload
  end

  test "should not update text push with empty payload" do
    push = Push.create!(
      kind: "text",
      payload: "Original password",
      user: @user
    )

    push.payload = ""
    assert_not push.valid?
    assert_includes push.errors[:payload], "Payload is required."
  end

  test "should not update text push with payload exceeding 1MB" do
    push = Push.create!(
      kind: "text",
      payload: "Original password",
      user: @user
    )

    push.payload = "a" * (1.megabyte + 1)
    assert_not push.valid?
    assert_includes push.errors[:payload], "The payload is too large.  You can only push up to 1048576 bytes."
  end

  test "should update url push with valid URL" do
    push = Push.create!(
      kind: "url",
      payload: "https://example.com",
      user: @user
    )

    push.payload = "https://updated-example.com"
    assert push.save
    assert_equal "https://updated-example.com", push.payload
  end

  test "should not update url push with invalid URL" do
    push = Push.create!(
      kind: "url",
      payload: "https://example.com",
      user: @user
    )

    push.payload = "not-a-valid-url"
    assert_not push.valid?
    assert_includes push.errors[:payload], "must be a valid HTTP or HTTPS URL."
  end

  test "should not update url push with empty payload" do
    push = Push.create!(
      kind: "url",
      payload: "https://example.com",
      user: @user
    )

    push.payload = ""
    assert_not push.valid?
    assert_includes push.errors[:payload], "Payload is required."
  end

  test "should update qr push with valid content within 1024 characters" do
    push = Push.create!(
      kind: "qr",
      payload: "Original QR content",
      user: @user
    )

    push.payload = "Updated QR content"
    assert push.save
    assert_equal "Updated QR content", push.payload
  end

  test "should not update qr push with payload exceeding 1024 characters" do
    push = Push.create!(
      kind: "qr",
      payload: "Original QR content",
      user: @user
    )

    push.payload = "a" * 1025
    assert_not push.valid?
    assert_includes push.errors[:payload], "The QR code payload is too large.  You can only push up to 1024 bytes."
  end

  test "should not update qr push with empty payload" do
    push = Push.create!(
      kind: "qr",
      payload: "Original QR content",
      user: @user
    )

    push.payload = ""
    assert_not push.valid?
    assert_includes push.errors[:payload], "Payload is required."
  end

  test "should update qr push with exactly 1024 characters" do
    push = Push.create!(
      kind: "qr",
      payload: "Original QR content",
      user: @user
    )

    push.payload = "a" * 1024
    assert push.save
    assert_equal 1024, push.payload.length
  end

  test "should update push name" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      name: "Original Name",
      user: @user
    )

    push.name = "Updated Name"
    assert push.save
    assert_equal "Updated Name", push.name
  end

  test "should update push note" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      note: "Original note",
      user: @user
    )

    push.note = "Updated note"
    assert push.save
    assert_equal "Updated note", push.note
  end

  test "should update push passphrase" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      passphrase: "old_passphrase",
      user: @user
    )

    push.passphrase = "new_passphrase"
    assert push.save
    assert_equal "new_passphrase", push.passphrase
  end

  test "should update expire_after_days" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      expire_after_days: 5,
      user: @user
    )

    push.expire_after_days = 10
    assert push.save
    assert_equal 10, push.expire_after_days
  end

  test "should update expire_after_views" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      expire_after_views: 5,
      user: @user
    )

    push.expire_after_views = 10
    assert push.save
    assert_equal 10, push.expire_after_views
  end

  test "should update retrieval_step" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      retrieval_step: false,
      user: @user
    )

    push.retrieval_step = true
    assert push.save
    assert push.retrieval_step
  end

  test "should update deletable_by_viewer" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      deletable_by_viewer: false,
      user: @user
    )

    push.deletable_by_viewer = true
    assert push.save
    assert push.deletable_by_viewer
  end

  test "should not change url_token on update" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      user: @user
    )

    original_token = push.url_token
    push.payload = "Updated password"
    push.save

    assert_equal original_token, push.url_token
  end

  test "should not change created_at on update" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      user: @user
    )

    original_created_at = push.created_at
    sleep 0.1
    push.payload = "Updated password"
    push.save

    assert_equal original_created_at.to_i, push.created_at.to_i
  end
end
