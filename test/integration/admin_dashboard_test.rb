# frozen_string_literal: true

require "test_helper"

class AdminDashboardTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Rails.application.reload_routes!
  end

  teardown do
    Settings.enable_logins = false
    Rails.application.reload_routes!
  end

  # Test that admin routes are not available when logins are disabled
  def test_admin_routes_not_available_when_logins_disabled
    Settings.enable_logins = false
    Rails.application.reload_routes!

    get "/admin"
    assert_response :not_found

    get "/admin/users"
    assert_response :not_found

    get "/admin/jobs"
    assert_response :not_found

    get "/admin/dbexplore"
    assert_response :not_found
  end

  # Test that admin routes are not available to unauthenticated users
  def test_admin_routes_not_available_to_unauthenticated_users
    get admin_root_path
    assert_response :not_found

    get admin_users_path
    assert_response :not_found

    get "/admin/jobs"
    assert_response :not_found

    get "/admin/dbexplore"
    assert_response :not_found
  end

  # Test that admin routes are not available to non-admin users
  def test_admin_routes_not_available_to_non_admin_users
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    get admin_root_path
    assert_response :not_found

    get admin_users_path
    assert_response :not_found

    get "/admin/jobs"
    assert_response :not_found

    get madmin_root_path
    assert_response :not_found

    sign_out @luca
  end

  # Test that admin routes are available to admin users
  def test_admin_routes_available_to_admin_users
    @mr_admin = users(:mr_admin)
    sign_in @mr_admin

    get admin_root_path
    assert_response :success
    assert_select "h1", "Administration Center"
    assert_select ".badge", text: /OSS Version/

    get admin_users_path
    assert_response :success
    assert_select "a", text: "Admin Users"

    get "/admin/jobs"
    assert_response :success

    get "/admin/dbexplore"
    assert_response :success
    assert_select "h4", "Direct Database Access"

    sign_out @mr_admin
  end

  # Test admin user management functionality
  def test_admin_user_management_functionality
    @mr_admin = users(:mr_admin)
    @luca = users(:luca)
    @luca.confirm
    sign_in @mr_admin

    # Test promote user to admin
    patch promote_admin_user_path(@luca)
    assert_response :redirect
    @luca.reload
    assert @luca.admin?

    # Test revoke admin privileges
    patch revoke_admin_user_path(@luca)
    assert_response :redirect
    @luca.reload
    assert_not @luca.admin?

    # Test that admin cannot revoke their own privileges
    patch revoke_admin_user_path(@mr_admin)
    assert_response :redirect
    @mr_admin.reload
    assert @mr_admin.admin?

    sign_out @mr_admin
  end

  # Test that non-admin users cannot access user management
  def test_user_management_not_available_to_non_admin_users
    @luca = users(:luca)
    @luca.confirm
    @giuliana = users(:giuliana)
    sign_in @luca

    # Test promote action
    patch promote_admin_user_path(@giuliana)
    assert_response :not_found

    # Test revoke action
    patch revoke_admin_user_path(@giuliana)
    assert_response :not_found

    sign_out @luca
  end

  # Test Data Explorer (Madmin) functionality
  def test_data_explorer_functionality
    @mr_admin = users(:mr_admin)
    sign_in @mr_admin

    # Test main dashboard
    get madmin_root_path
    assert_response :success
    assert_select "h4", "Direct Database Access"

    # Test users resource
    get madmin_users_path
    assert_response :success

    # Test pushes resource
    get madmin_pushes_path
    assert_response :success

    # Test audit logs resource
    get madmin_audit_logs_path
    assert_response :success

    # Test Active Storage resources
    get madmin_active_storage_blobs_path
    assert_response :success

    get madmin_active_storage_attachments_path
    assert_response :success

    get madmin_active_storage_variant_records_path
    assert_response :success

    sign_out @mr_admin
  end

  # Test that Data Explorer is not available to non-admin users
  def test_data_explorer_not_available_to_non_admin_users
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    get madmin_root_path
    assert_response :not_found

    get madmin_users_path
    assert_response :not_found

    get madmin_pushes_path
    assert_response :not_found

    get madmin_audit_logs_path
    assert_response :not_found

    sign_out @luca
  end

  # Test Background Jobs (MissionControl::Jobs) functionality
  def test_background_jobs_functionality
    @mr_admin = users(:mr_admin)
    sign_in @mr_admin

    get "/admin/jobs"
    assert_response :success
    assert_select "h1", "Background Jobs"

    sign_out @mr_admin
  end

  # Test that Background Jobs is not available to non-admin users
  def test_background_jobs_not_available_to_non_admin_users
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    get "/admin/jobs"
    assert_response :not_found

    sign_out @luca
  end

  # Test admin dashboard content and statistics
  def test_admin_dashboard_content
    @mr_admin = users(:mr_admin)
    sign_in @mr_admin

    get admin_root_path
    assert_response :success

    # Test that statistics are displayed
    assert_select ".card", minimum: 4  # At least 4 stat cards
    assert_select "p", text: /Total Users/
    assert_select "p", text: /Total Pushes/
    assert_select "p", text: /Total Audit Logs/

    # Test that main sections are present
    assert_select "h2", text: /System Administration/
    assert_select "h2", text: /Database Administration/
    assert_select "h2", text: /Resources & Support/

    # Test that Getting Started section is present
    assert_select "h2", text: /Getting Started/

    sign_out @mr_admin
  end
end
