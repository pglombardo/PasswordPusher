# frozen_string_literal: true

require "test_helper"

class OwnerAndAdminViewTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Rails.application.reload_routes!

    @owner = users(:luca)
    @admin = users(:mr_admin)
    @other_user = users(:one)
  end

  teardown do
    sign_out :user
  end

  # Test that owner views don't count towards view limit
  test "owner viewing their own push does not count towards view limit" do
    sign_in @owner

    # Create a push with limited views
    post pushes_path, params: {
      push: {
        kind: "text",
        payload: "owner_test_password",
        expire_after_days: 7,
        expire_after_views: 5
      }
    }
    follow_redirect!

    url_token = request.url.match("/p/(.*)/preview")[1]
    push = Push.find_by(url_token: url_token)

    initial_view_count = push.view_count
    initial_views_remaining = push.views_remaining

    # Owner views their own push
    get push_path(push)
    assert_response :success

    push.reload
    # View count should NOT increase (owner_view doesn't count)
    assert_equal initial_view_count, push.view_count, "Owner view should not increment view_count"
    assert_equal initial_views_remaining, push.views_remaining, "Owner view should not decrement views_remaining"

    # Check that an owner_view audit log was created
    owner_view_logs = push.audit_logs.where(kind: :owner_view)
    assert_equal 1, owner_view_logs.count, "Should have one owner_view audit log"
    assert_equal @owner.id, owner_view_logs.first.user_id, "owner_view should be associated with owner"
  end

  # Test that admin views don't count towards view limit
  test "admin viewing any push does not count towards view limit" do
    sign_in @owner

    # Create a push with limited views
    post pushes_path, params: {
      push: {
        kind: "text",
        payload: "admin_test_password",
        expire_after_days: 7,
        expire_after_views: 5
      }
    }
    follow_redirect!

    url_token = request.url.match("/p/(.*)/preview")[1]
    push = Push.find_by(url_token: url_token)

    sign_out @owner
    sign_in @admin

    initial_view_count = push.view_count
    initial_views_remaining = push.views_remaining

    # Admin views the push
    get push_path(push)
    assert_response :success

    push.reload
    # View count should NOT increase (admin_view doesn't count)
    assert_equal initial_view_count, push.view_count, "Admin view should not increment view_count"
    assert_equal initial_views_remaining, push.views_remaining, "Admin view should not decrement views_remaining"

    # Check that an admin_view audit log was created
    admin_view_logs = push.audit_logs.where(kind: :admin_view)
    assert_equal 1, admin_view_logs.count, "Should have one admin_view audit log"
    assert_equal @admin.id, admin_view_logs.first.user_id, "admin_view should be associated with admin"
  end

  # Test that regular user views DO count towards view limit
  test "regular user viewing push counts towards view limit" do
    sign_in @owner

    # Create a push with limited views
    post pushes_path, params: {
      push: {
        kind: "text",
        payload: "regular_user_test_password",
        expire_after_days: 7,
        expire_after_views: 5
      }
    }
    follow_redirect!

    url_token = request.url.match("/p/(.*)/preview")[1]
    push = Push.find_by(url_token: url_token)

    sign_out @owner
    sign_in @other_user

    initial_view_count = push.view_count
    initial_views_remaining = push.views_remaining

    # Regular user views the push
    get push_path(push)
    assert_response :success

    push.reload
    # View count SHOULD increase (regular view counts)
    assert_equal initial_view_count + 1, push.view_count, "Regular user view should increment view_count"
    assert_equal initial_views_remaining - 1, push.views_remaining, "Regular user view should decrement views_remaining"

    # Check that a regular view audit log was created
    view_logs = push.audit_logs.where(kind: :view)
    assert_equal 1, view_logs.count, "Should have one regular view audit log"
  end

  # Test that anonymous views DO count towards view limit
  test "anonymous user viewing push counts towards view limit" do
    sign_in @owner

    # Create a push with limited views
    post pushes_path, params: {
      push: {
        kind: "text",
        payload: "anonymous_test_password",
        expire_after_days: 7,
        expire_after_views: 5
      }
    }
    follow_redirect!

    url_token = request.url.match("/p/(.*)/preview")[1]
    push = Push.find_by(url_token: url_token)

    sign_out @owner

    initial_view_count = push.view_count
    initial_views_remaining = push.views_remaining

    # Anonymous user views the push
    get push_path(push)
    assert_response :success

    push.reload
    # View count SHOULD increase (anonymous view counts)
    assert_equal initial_view_count + 1, push.view_count, "Anonymous view should increment view_count"
    assert_equal initial_views_remaining - 1, push.views_remaining, "Anonymous view should decrement views_remaining"

    # Check that a regular view audit log was created
    view_logs = push.audit_logs.where(kind: :view)
    assert_equal 1, view_logs.count, "Should have one regular view audit log"
    assert_nil view_logs.first.user_id, "Anonymous view should not be associated with a user"
  end

  # Test owner can view multiple times without affecting count
  test "owner can view push multiple times without affecting view limit" do
    sign_in @owner

    # Create a push with only 2 views allowed
    post pushes_path, params: {
      push: {
        kind: "text",
        payload: "multi_owner_view_test",
        expire_after_days: 7,
        expire_after_views: 2
      }
    }
    follow_redirect!

    url_token = request.url.match("/p/(.*)/preview")[1]
    push = Push.find_by(url_token: url_token)

    initial_view_count = push.view_count
    initial_views_remaining = push.views_remaining

    # Owner views 3 times
    3.times do
      get push_path(push)
      assert_response :success
    end

    push.reload
    # View count should still be 0 (no regular views)
    assert_equal initial_view_count, push.view_count, "Multiple owner views should not increment view_count"
    assert_equal initial_views_remaining, push.views_remaining, "Multiple owner views should not decrement views_remaining"

    # Should have 3 owner_view audit logs
    owner_view_logs = push.audit_logs.where(kind: :owner_view)
    assert_equal 3, owner_view_logs.count, "Should have three owner_view audit logs"

    # Push should not be expired
    push.reload
    assert_not push.expired, "Push should not be expired from owner views"
  end

  # Test mixed scenario: owner, admin, and regular views
  test "mixed owner admin and regular views are tracked correctly" do
    sign_in @owner

    # Create a push with 10 views allowed
    post pushes_path, params: {
      push: {
        kind: "text",
        payload: "mixed_view_test",
        expire_after_days: 7,
        expire_after_views: 10
      }
    }
    follow_redirect!

    url_token = request.url.match("/p/(.*)/preview")[1]
    push = Push.find_by(url_token: url_token)

    # Owner views twice
    2.times do
      get push_path(push)
      assert_response :success
    end

    sign_out @owner
    sign_in @admin

    # Admin views twice
    2.times do
      get push_path(push)
      assert_response :success
    end

    sign_out @admin
    sign_in @other_user

    # Regular user views 3 times
    3.times do
      get push_path(push)
      assert_response :success
    end

    push.reload

    # View count should only be 3 (from regular user)
    assert_equal 3, push.view_count, "Only regular views should count"
    assert_equal 7, push.views_remaining, "Views remaining should only decrease from regular views"

    # Verify audit log counts
    assert_equal 2, push.audit_logs.where(kind: :owner_view).count, "Should have 2 owner_view logs"
    assert_equal 2, push.audit_logs.where(kind: :admin_view).count, "Should have 2 admin_view logs"
    assert_equal 3, push.audit_logs.where(kind: :view).count, "Should have 3 regular view logs"
  end

  # Test that owner_view audit logs appear in audit page
  test "owner can see owner_view logs in audit page" do
    sign_in @owner

    # Create a push
    post pushes_path, params: {
      push: {
        kind: "text",
        payload: "audit_page_test",
        expire_after_days: 7,
        expire_after_views: 5
      }
    }
    follow_redirect!

    url_token = request.url.match("/p/(.*)/preview")[1]
    push = Push.find_by(url_token: url_token)

    # Owner views the push
    get push_path(push)
    assert_response :success

    # View audit log page
    get audit_push_path(push)
    assert_response :success

    # Should see owner_view in audit log
    assert_select ".list-group-item-info", {text: /Owner view/, count: 1}
    assert_select ".badge", {text: /Does not count towards view limit/, count: 1}
  end

  # Test that admin_view audit logs appear in audit page
  test "owner can see admin_view logs in audit page when admin views their push" do
    sign_in @owner

    # Create a push
    post pushes_path, params: {
      push: {
        kind: "text",
        payload: "admin_audit_page_test",
        expire_after_days: 7,
        expire_after_views: 5
      }
    }
    follow_redirect!

    url_token = request.url.match("/p/(.*)/preview")[1]
    push = Push.find_by(url_token: url_token)

    sign_out @owner
    sign_in @admin

    # Admin views the push
    get push_path(push)
    assert_response :success

    sign_out @admin
    sign_in @owner

    # View audit log page as owner
    get audit_push_path(push)
    assert_response :success

    # Should see admin_view in audit log
    assert_select ".list-group-item-info", {text: /Admin view/, count: 1}
    assert_select ".badge", {text: /Does not count towards view limit/, count: 1}
  end

  # Test push expiration still works correctly with owner/admin views
  test "push expires correctly after regular views even with owner and admin views" do
    sign_in @owner

    # Create a push with only 1 view allowed
    post pushes_path, params: {
      push: {
        kind: "text",
        payload: "expiration_test",
        expire_after_days: 7,
        expire_after_views: 1
      }
    }
    follow_redirect!

    url_token = request.url.match("/p/(.*)/preview")[1]
    push = Push.find_by(url_token: url_token)

    # Owner views multiple times - should NOT expire
    5.times do
      get push_path(push)
      assert_response :success
    end

    push.reload
    assert_not push.expired, "Push should not expire from owner views"

    sign_out @owner
    sign_in @admin

    # Admin views multiple times - should NOT expire
    5.times do
      get push_path(push)
      assert_response :success
    end

    push.reload
    assert_not push.expired, "Push should not expire from admin views"

    sign_out @admin

    # Anonymous user views once - SHOULD expire
    get push_path(push)
    assert_response :success

    push.reload
    assert push.expired, "Push should expire after 1 regular view"
  end
end
