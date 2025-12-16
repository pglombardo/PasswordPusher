# frozen_string_literal: true

require "test_helper"

class UrlPushEditTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_url_pushes = true
    Rails.application.reload_routes!
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca
  end

  teardown do
    sign_out :user
  end

  test "authenticated user can access edit page for their own url push" do
    push = Push.create!(
      kind: "url",
      payload: "https://example.com",
      user: @luca
    )

    get edit_push_path(push)
    assert_response :success
    assert_select "input#push_payload[value=?]", "https://example.com"
  end

  test "edit page shows current expire values for url push" do
    push = Push.create!(
      kind: "url",
      payload: "https://example.com",
      user: @luca,
      expire_after_days: 15,
      expire_after_views: 30
    )

    get edit_push_path(push)
    assert_response :success

    # Verify data attributes contain current push values
    assert_select "div[data-knobs-default-days-value='15']"
    assert_select "div[data-knobs-default-views-value='30']"

    # Verify range fields have correct values
    assert_select "input[name='push[expire_after_days]'][value='15']"
    assert_select "input[name='push[expire_after_views]'][value='30']"
  end

  test "can update url push with valid url" do
    push = Push.create!(
      kind: "url",
      payload: "https://example.com",
      name: "Original Name",
      user: @luca,
      expire_after_days: 5,
      expire_after_views: 10
    )

    patch push_path(push), params: {
      push: {
        kind: "url",
        payload: "https://updated-example.com",
        name: "Updated Name",
        expire_after_days: 7,
        expire_after_views: 15
      }
    }

    assert_redirected_to preview_push_path(push)

    push.reload
    assert_equal "https://updated-example.com", push.payload
    assert_equal "Updated Name", push.name
    assert_equal 7, push.expire_after_days
    assert_equal 15, push.expire_after_views
  end

  test "update shows validation errors for invalid url" do
    push = Push.create!(
      kind: "url",
      payload: "https://example.com",
      user: @luca
    )

    patch push_path(push), params: {
      push: {
        kind: "url",
        payload: "not-a-valid-url"
      }
    }

    assert_response :unprocessable_content
    assert_select "div.alert-danger", text: /must be a valid HTTP or HTTPS URL/
  end

  test "cannot edit url push belonging to another user" do
    other_user = users(:one)

    push = Push.create!(
      kind: "url",
      payload: "https://other-user.com",
      user: other_user
    )

    get edit_push_path(push)
    assert_redirected_to root_path

    patch push_path(push), params: {
      push: {
        kind: "url",
        payload: "https://hacked.com"
      }
    }
    assert_redirected_to root_path

    push.reload
    assert_equal "https://other-user.com", push.payload
  end

  test "can edit note on expired url push" do
    push = Push.create!(
      kind: "url",
      payload: "https://example.com",
      note: "Original note",
      user: @luca
    )

    # Manually set expired without triggering validations
    push.update_columns(expired: true, expired_on: Time.current, payload_ciphertext: nil)

    get edit_push_path(push)
    assert_response :success

    patch push_path(push), params: {
      push: {
        note: "Updated note for expired URL push"
      }
    }
    assert_redirected_to preview_push_path(push)

    push.reload
    assert_equal "Updated note for expired URL push", push.note
  end

  test "cannot edit payload on expired url push" do
    push = Push.create!(
      kind: "url",
      payload: "https://example.com",
      note: "Original note",
      user: @luca
    )

    # Manually set expired without triggering validations
    push.update_columns(expired: true, expired_on: Time.current, payload_ciphertext: nil)

    patch push_path(push), params: {
      push: {
        payload: "https://new-url.com"
      }
    }
    assert_redirected_to edit_push_path(push)
    follow_redirect!
    assert_match(/can only have their note or name updated/i, response.body)
  end

  test "edit page shows update button for url push" do
    push = Push.create!(
      kind: "url",
      payload: "https://example.com",
      user: @luca
    )

    get edit_push_path(push)
    assert_response :success
    assert_select "button[type=submit]", text: /Update Push/
  end

  test "expired url push edit page shows edit button and hides restricted inputs" do
    push = Push.create!(
      kind: "url",
      payload: "https://expired.com",
      name: "Test URL Push",
      note: "Test note",
      user: @luca
    )
    push.update_columns(expired: true, expired_on: Time.current, payload_ciphertext: nil)

    get edit_push_path(push)
    assert_response :success

    # Edit button/form should be present
    assert_select "button[type=submit]", text: /Update Push/

    # Name and note fields should be present (editable)
    assert_select "input#push_name"
    assert_select "textarea#push_note"

    # URL payload field should be disabled
    assert_select "input#push_payload[disabled][readonly]"

    # Expiration settings should be disabled
    assert_select "input[name='push[expire_after_days]'][disabled]"
    assert_select "input[name='push[expire_after_views]'][disabled]"

    # Passphrase field should be disabled
    assert_select "input#push_passphrase[disabled]"

    # Retrieval step checkbox should be disabled
    assert_select "input[name='push[retrieval_step]'][disabled]"
  end

  test "attempting to update restricted fields on expired url push shows error not success" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    push = Push.create!(
      kind: :url,
      payload: "https://original.com",
      note: "Original note",
      user: @luca
    )
    push.update_columns(expired: true, expired_on: Time.current, payload_ciphertext: nil)

    # Simulate user removing disabled attributes and trying to update restricted fields
    patch push_path(push), params: {
      push: {
        payload: "https://new.com", # Restricted field
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
