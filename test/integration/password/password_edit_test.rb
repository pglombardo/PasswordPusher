# frozen_string_literal: true

require "test_helper"

class PasswordEditTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca
  end

  teardown do
    sign_out :user
  end

  test "authenticated user can access edit page for their own push" do
    push = Push.create!(
      kind: "text",
      payload: "Original password",
      user: @luca,
      expire_after_days: 5,
      expire_after_views: 10
    )

    get edit_push_path(push)
    assert_response :success
    assert_select "textarea#push_payload", text: "Original password"
  end

  test "edit page shows correct values for text push" do
    push = Push.create!(
      kind: "text",
      payload: "Test password",
      name: "My Push",
      note: "My note",
      user: @luca,
      expire_after_days: 7,
      expire_after_views: 5,
      retrieval_step: true,
      deletable_by_viewer: true
    )

    get edit_push_path(push)
    assert_response :success

    assert_select "textarea#push_payload", text: "Test password"
    assert_select "input#push_name[value=?]", "My Push"
    assert_select "textarea#push_note", text: "My note"
    assert_select "button[type=submit]", text: /Update Push/
  end

  test "edit page shows current expire values in form" do
    push = Push.create!(
      kind: "text",
      payload: "Test password",
      user: @luca,
      expire_after_days: 12,
      expire_after_views: 25
    )

    get edit_push_path(push)
    assert_response :success

    # Verify data attributes contain current push values
    assert_select "div[data-knobs-default-days-value='12']"
    assert_select "div[data-knobs-default-views-value='25']"

    # Verify range fields have correct values
    assert_select "input[name='push[expire_after_days]'][value='12']"
    assert_select "input[name='push[expire_after_views]'][value='25']"
  end

  test "can update push with valid data" do
    push = Push.create!(
      kind: "text",
      payload: "Original password",
      name: "Original Name",
      user: @luca,
      expire_after_days: 5,
      expire_after_views: 10
    )

    initial_audit_count = push.audit_logs.count

    patch push_path(push), params: {
      push: {
        kind: "text",
        payload: "Updated password",
        name: "Updated Name",
        expire_after_days: 7,
        expire_after_views: 15
      }
    }

    assert_redirected_to preview_push_path(push)
    follow_redirect!
    assert_response :success

    push.reload
    assert_equal "Updated password", push.payload
    assert_equal "Updated Name", push.name
    assert_equal 7, push.expire_after_days
    assert_equal 15, push.expire_after_views

    # Verify audit log entry was created
    assert_equal initial_audit_count + 1, push.audit_logs.count
    assert push.audit_logs.last.update_push?
  end

  test "update shows validation errors for invalid data" do
    push = Push.create!(
      kind: "text",
      payload: "Original password",
      user: @luca
    )

    patch push_path(push), params: {
      push: {
        kind: "text",
        payload: ""  # Invalid - empty payload
      }
    }

    assert_response :unprocessable_content
    assert_select "div.alert-danger", text: /Payload is required/
  end

  test "cannot edit push belonging to another user" do
    other_user = users(:one)  # Use existing fixture

    push = Push.create!(
      kind: "text",
      payload: "Other user's password",
      user: other_user
    )

    get edit_push_path(push)
    assert_redirected_to root_path

    patch push_path(push), params: {
      push: {
        kind: "text",
        payload: "Hacked password"
      }
    }
    assert_redirected_to root_path

    push.reload
    assert_equal "Other user's password", push.payload
  end

  test "can edit note on expired push" do
    push = Push.create!(
      kind: "text",
      payload: "Expired password",
      note: "Original note",
      user: @luca
    )

    # Manually set expired without triggering validations
    push.update_columns(expired: true, expired_on: Time.current, payload_ciphertext: nil)

    get edit_push_path(push)
    assert_response :success

    patch push_path(push), params: {
      push: {
        note: "Updated note for expired push"
      }
    }
    assert_redirected_to preview_push_path(push)

    push.reload
    assert_equal "Updated note for expired push", push.note
  end

  test "cannot edit payload on expired push" do
    push = Push.create!(
      kind: "text",
      payload: "Expired password",
      note: "Original note",
      user: @luca
    )

    # Manually set expired without triggering validations
    push.update_columns(expired: true, expired_on: Time.current, payload_ciphertext: nil)

    patch push_path(push), params: {
      push: {
        payload: "New password"
      }
    }
    assert_redirected_to edit_push_path(push)
    follow_redirect!
    assert_match(/can only have their note or name updated/i, response.body)
  end

  test "can edit name on expired push" do
    push = Push.create!(
      kind: "text",
      payload: "Expired password",
      name: "Original name",
      user: @luca
    )

    # Manually set expired without triggering validations
    push.update_columns(expired: true, expired_on: Time.current, payload_ciphertext: nil)

    patch push_path(push), params: {
      push: {
        name: "Updated name"
      }
    }
    assert_redirected_to preview_push_path(push)

    push.reload
    assert_equal "Updated name", push.name
  end

  test "can update passphrase" do
    push = Push.create!(
      kind: "text",
      payload: "Secret password",
      passphrase: "old_passphrase",
      user: @luca
    )

    patch push_path(push), params: {
      push: {
        kind: "text",
        payload: "Secret password",
        passphrase: "new_passphrase"
      }
    }

    assert_redirected_to preview_push_path(push)
    push.reload
    assert_equal "new_passphrase", push.passphrase
  end

  test "can update note" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      note: "Original note",
      user: @luca
    )

    patch push_path(push), params: {
      push: {
        kind: "text",
        payload: "Password",
        note: "Updated note"
      }
    }

    assert_redirected_to preview_push_path(push)
    push.reload
    assert_equal "Updated note", push.note
  end

  test "can toggle retrieval_step" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      retrieval_step: false,
      user: @luca
    )

    patch push_path(push), params: {
      push: {
        kind: "text",
        payload: "Password",
        retrieval_step: "1"
      }
    }

    assert_redirected_to preview_push_path(push)
    push.reload
    assert push.retrieval_step
  end

  test "can toggle deletable_by_viewer" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      deletable_by_viewer: false,
      user: @luca
    )

    patch push_path(push), params: {
      push: {
        kind: "text",
        payload: "Password",
        deletable_by_viewer: "1"
      }
    }

    assert_redirected_to preview_push_path(push)
    push.reload
    assert push.deletable_by_viewer
  end

  test "expired push edit page shows edit button and hides restricted inputs" do
    push = Push.create!(
      kind: "text",
      payload: "Expired password",
      name: "Test Push",
      note: "Test note",
      user: @luca,
      passphrase: "secret"
    )
    push.update_columns(expired: true, expired_on: Time.current, payload_ciphertext: nil)

    get edit_push_path(push)
    assert_response :success

    # Edit button/form should be present
    assert_select "button[type=submit]", text: /Update Push/

    # Name and note fields should be present (editable)
    assert_select "input#push_name"
    assert_select "textarea#push_note"

    # Payload field should be disabled
    assert_select "textarea#push_payload[disabled][readonly]"

    # Expiration settings should be disabled
    assert_select "input[name='push[expire_after_days]'][disabled]"
    assert_select "input[name='push[expire_after_views]'][disabled]"

    # Passphrase field should be disabled
    assert_select "input#push_passphrase[disabled]"

    # Password generator button should be disabled
    assert_select "button#generate_password[disabled]"

    # Checkboxes should be disabled
    assert_select "input[name='push[retrieval_step]'][disabled]"
    assert_select "input[name='push[deletable_by_viewer]'][disabled]"
  end

  test "attempting to update restricted fields on expired push shows error not success" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    push = Push.create!(
      kind: :text,
      payload: "Original password",
      note: "Original note",
      user: @luca
    )
    push.update_columns(expired: true, expired_on: Time.current, payload_ciphertext: nil)

    # Simulate user removing disabled attributes and trying to update restricted fields
    patch push_path(push), params: {
      push: {
        payload: "New password", # Restricted field
        expire_after_days: 5, # Restricted field
        expire_after_views: 10, # Restricted field
        passphrase: "newpass" # Restricted field
      }
    }

    # Should redirect with alert
    assert_redirected_to edit_push_path(push)
    follow_redirect!

    # Should show alert message about restricted fields being logged
    assert_match(/restricted fields has been logged/i, response.body)
    assert_no_match(/successfully updated/i, response.body)
  end
end
