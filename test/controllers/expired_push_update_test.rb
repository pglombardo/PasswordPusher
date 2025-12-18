# frozen_string_literal: true

require "test_helper"

class ExpiredPushUpdateTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!

    @luca = users(:luca)
    @luca.confirm
    sign_in @luca
  end

  teardown do
    sign_out @luca
    Settings.enable_logins = false
    Settings.enable_file_pushes = false
  end

  test "can update note on expired text push" do
    push = Push.create!(
      kind: "text",
      payload: "secret password",
      user: @luca,
      expired: true
    )

    patch push_path(push), params: {
      push: {
        note: "Updated note for expired push"
      }
    }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert response.body.include?("Note was successfully updated")

    push.reload
    assert_equal "Updated note for expired push", push.note
  end

  test "can update name on expired text push" do
    push = Push.create!(
      kind: "text",
      payload: "secret password",
      user: @luca,
      expired: true
    )

    patch push_path(push), params: {
      push: {
        name: "Updated name"
      }
    }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert response.body.include?("Note was successfully updated")

    push.reload
    assert_equal "Updated name", push.name
  end

  test "cannot update payload on expired text push" do
    push = Push.create!(
      kind: "text",
      payload: "secret password",
      user: @luca,
      expired: true
    )

    original_payload = push.payload

    patch push_path(push), params: {
      push: {
        payload: "new secret password",
        note: "Trying to update payload"
      }
    }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert response.body.include?("Expired pushes can only have their note or name updated")

    push.reload
    assert_equal original_payload, push.payload
    assert_not_equal "Trying to update payload", push.note
  end

  test "cannot update expiration settings on expired text push" do
    push = Push.create!(
      kind: "text",
      payload: "secret password",
      user: @luca,
      expired: true,
      expire_after_days: 7,
      expire_after_views: 5
    )

    patch push_path(push), params: {
      push: {
        expire_after_days: 30,
        expire_after_views: 100,
        note: "Trying to extend expiration"
      }
    }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert response.body.include?("Expired pushes can only have their note or name updated")

    push.reload
    assert_equal 7, push.expire_after_days
    assert_equal 5, push.expire_after_views
  end

  test "cannot update passphrase on expired text push" do
    push = Push.create!(
      kind: "text",
      payload: "secret password",
      user: @luca,
      expired: true
    )

    patch push_path(push), params: {
      push: {
        passphrase: "new-passphrase",
        note: "Trying to add passphrase"
      }
    }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert response.body.include?("Expired pushes can only have their note or name updated")

    push.reload
    # Lockbox returns empty string for blank passphrases
    assert_equal "", push.passphrase
  end

  test "cannot upload files to expired file push" do
    push = Push.create!(
      kind: "file",
      user: @luca,
      expired: true
    )
    file = fixture_file_upload("test-file.txt", "text/plain")
    push.files.attach(file)

    new_file = fixture_file_upload("test-file.txt", "text/plain")

    patch push_path(push), params: {
      push: {
        files: [new_file],
        note: "Trying to upload more files"
      }
    }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert response.body.include?("Files cannot be uploaded to expired pushes")

    push.reload
    assert_equal 1, push.files.count
  end

  test "logs failed update attempt when modifying restricted fields" do
    push = Push.create!(
      kind: "text",
      payload: "secret password",
      user: @luca,
      expired: true
    )

    initial_audit_count = push.audit_logs.count

    patch push_path(push), params: {
      push: {
        payload: "new secret password",
        note: "Attempting security bypass"
      }
    }
    assert_response :redirect

    push.reload
    assert_equal initial_audit_count + 1, push.audit_logs.count

    failed_audit = push.audit_logs.last
    assert_equal "failed_update", failed_audit.kind
    assert_equal @luca, failed_audit.user
  end

  test "logs failed update attempt when uploading files to expired push" do
    push = Push.create!(
      kind: "file",
      user: @luca,
      expired: true
    )
    file = fixture_file_upload("test-file.txt", "text/plain")
    push.files.attach(file)

    initial_audit_count = push.audit_logs.count

    new_file = fixture_file_upload("test-file.txt", "text/plain")
    patch push_path(push), params: {
      push: {
        files: [new_file],
        note: "DOM bypass attempt"
      }
    }
    assert_response :redirect

    push.reload
    assert_equal initial_audit_count + 1, push.audit_logs.count

    failed_audit = push.audit_logs.last
    assert_equal "failed_update", failed_audit.kind
    assert_equal @luca, failed_audit.user
  end

  test "can update note and name together on expired push" do
    push = Push.create!(
      kind: "text",
      payload: "secret password",
      user: @luca,
      expired: true
    )

    patch push_path(push), params: {
      push: {
        note: "Updated note",
        name: "Updated name"
      }
    }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    push.reload
    assert_equal "Updated note", push.note
    assert_equal "Updated name", push.name
  end

  test "cannot update push that doesn't belong to current user" do
    other_user = User.create!(
      email: "other@example.com",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    push = Push.create!(
      kind: "text",
      payload: "secret password",
      user: other_user,
      expired: true
    )

    patch push_path(push), params: {
      push: {
        note: "Trying to update someone else's push"
      }
    }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert flash[:notice].include?("doesn't belong to you")

    push.reload
    assert_not_equal "Trying to update someone else's push", push.note
  end

  test "can update non-expired push normally" do
    push = Push.create!(
      kind: "text",
      payload: "secret password",
      user: @luca,
      expire_after_days: 7,
      expire_after_views: 5
    )

    patch push_path(push), params: {
      push: {
        payload: "updated password",
        note: "Updated note",
        name: "Updated name",
        expire_after_days: 10,
        expire_after_views: 10
      }
    }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert response.body.include?("Push was successfully updated")

    push.reload
    assert_equal "updated password", push.payload
    assert_equal "Updated note", push.note
    assert_equal "Updated name", push.name
    assert_equal 10, push.expire_after_days
    assert_equal 10, push.expire_after_views
  end
end
