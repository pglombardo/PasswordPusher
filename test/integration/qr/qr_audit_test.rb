# frozen_string_literal: true

require "test_helper"

class QrAuditTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_qr_pushes = true

    # Create a user
    @luca = users(:luca)
    @paul = users(:one)
    sign_in @luca
  end

  teardown do
    sign_out :user
  end

  def test_user_can_view_audit_logs_for_own_push
    # Create a new push
    post pushes_path, params: {
      push: {
        kind: "qr",
        payload: "audit_test_text_payload",
        expire_after_days: 7,
        expire_after_views: 5
      }
    }
    follow_redirect!

    url_token = request.url.match("/p/(.*)/preview")[1]
    push = Push.find_by(url_token: url_token)

    get audit_push_path(push)
    assert_response :success
    assert_select "h4", {text: /Audit Log for Push ID: #{push.url_token}/}
    assert_select ".list-group-item-primary", {text: /Created on/, count: 1}
  end

  def test_user_cannot_view_audit_logs_for_other_users
    # Create a new push
    post pushes_path, params: {
      push: {
        kind: "qr",
        payload: "audit_test_text_payload",
        expire_after_days: 7,
        expire_after_views: 5
      }
    }
    follow_redirect!

    url_token = request.url.match("/p/(.*)/preview")[1]
    push = Push.find_by(url_token: url_token)

    sign_out :user
    sign_in @paul
    get audit_push_path(push)
    assert_response :redirect

    # Verify redirect with access denied message
    follow_redirect!

    assert_select ".alert", {text: /That push doesn't belong to you/, count: 1}
  end

  def test_anonymous_user_cannot_view_audit_logs
    post pushes_path, params: {
      push: {
        kind: "qr",
        payload: "audit_test_text_payload",
        expire_after_days: 7,
        expire_after_views: 5
      }
    }
    follow_redirect!

    url_token = request.url.match("/p/(.*)/preview")[1]
    push = Push.find_by(url_token: url_token)

    sign_out @luca

    get audit_push_path(push)
    assert_response :redirect

    # Should redirect to sign in
    follow_redirect!
    assert_select "h2", {text: /Log In/}
  end

  def test_audit_log_shows_creation_event_html_elements
    # Create a new push
    post pushes_path, params: {
      push: {
        kind: "qr",
        payload: "audit_test_text_payload",
        expire_after_days: 7,
        expire_after_views: 5
      }
    }
    follow_redirect!

    url_token = request.url.match("/p/(.*)/preview")[1]
    push = Push.find_by(url_token: url_token)

    # View the audit log
    get audit_push_path(push)
    assert_response :success

    # Check HTML elements for creation event
    assert_select "h4", {text: /Audit Log for Push ID: #{push.url_token}/}
    assert_select ".list-group-item-primary", {text: /Created on/, count: 1}
  end

  def test_audit_log_shows_view_event_html_elements
    # Create a new push
    post pushes_path, params: {
      push: {
        kind: "qr",
        payload: "audit_test_text_payload",
        expire_after_days: 7,
        expire_after_views: 5
      }
    }

    # View the push
    get push_path(@luca.pushes.last)
    assert_response :success

    # View the audit log
    get audit_push_path(@luca.pushes.last)
    assert_response :success

    # Check HTML elements for view event
    assert_select ".list-group-item-success", {text: /Successful view/, count: 1}
  end

  def test_audit_log_shows_failed_passphrase_event_html_elements
    # Create a push with passphrase
    post pushes_path, params: {
      push: {
        kind: "qr",
        payload: "passphrase_protected_payload",
        expire_after_days: 7,
        expire_after_views: 5,
        passphrase: "correct-passphrase"
      }
    }
    follow_redirect!

    url_token = request.url.match("/p/(.*)/preview")[1]
    push = Push.find_by(url_token: url_token)

    # Attempt to view with wrong passphrase
    post access_push_path(push), params: {passphrase: "wrong-passphrase"}

    # View the audit log
    get audit_push_path(push)
    assert_response :success

    assert_select ".list-group-item-warning", {text: /Failed passphrase attempt/, count: 1}
  end

  def test_audit_log_shows_expire_event_html_elements
    # Create a push with passphrase
    post pushes_path, params: {
      push: {
        kind: "qr",
        payload: "passphrase_protected_payload",
        expire_after_days: 7,
        expire_after_views: 5,
        passphrase: "correct-passphrase"
      }
    }
    follow_redirect!

    url_token = request.url.match("/p/(.*)/preview")[1]
    push = Push.find_by(url_token: url_token)

    # Expire the push
    delete expire_push_path(push)
    follow_redirect!

    # View the audit log
    get audit_push_path(push)
    assert_response :success

    assert_select ".list-group-item-danger", {text: /Manually expired on/, count: 1}
  end

  def test_audit_log_shows_failed_view_event_html_elements
    # Create a push
    post pushes_path, params: {
      push: {
        kind: "qr",
        payload: "asdf",
        expire_after_days: 7,
        expire_after_views: 1
      }
    }
    follow_redirect!

    url_token = request.url.match("/p/(.*)/preview")[1]
    push = Push.find_by(url_token: url_token)

    # View the push once to use up the view
    get push_path(push)
    assert_response :success

    # Try to view again (should fail)
    get push_path(push)
    assert_response :success

    # View the audit log
    get audit_push_path(push)
    assert_response :success

    # Check HTML elements for failed view event
    assert_select ".list-group-item-warning", {text: /Failed view attempt/, count: 1}
  end
end
