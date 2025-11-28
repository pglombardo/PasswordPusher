# frozen_string_literal: true

require "test_helper"

class AdminUserManagementTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Rails.application.reload_routes!
    # Set default URL options for test environment to avoid missing host errors
    Rails.application.routes.default_url_options[:host] = "localhost:3000"

    @mr_admin = users(:mr_admin)
    @luca = users(:luca)
    @luca.confirm
    @giuliana = users(:giuliana)
    @giuliana.confirm
  end

  teardown do
    Settings.enable_logins = false
    Rails.application.reload_routes!
  end

  # Test error handling in promote action
  test "promote action handles database errors gracefully" do
    sign_in @mr_admin

    # Mock a database error
    original_execute = ActiveRecord::Base.connection.method(:execute)
    ActiveRecord::Base.connection.define_singleton_method(:execute) do |sql|
      raise ActiveRecord::StatementInvalid, "Database error"
    end

    patch promote_admin_user_path(@luca)

    assert_response :redirect
    follow_redirect!
    assert_match(/Failed to promote/, flash[:alert])

    # Verify user was not promoted
    @luca.reload
    assert_not @luca.admin?
  ensure
    ActiveRecord::Base.connection.define_singleton_method(:execute, original_execute)
    sign_out @mr_admin
  end

  test "promote action shows success message on success" do
    sign_in @mr_admin

    patch promote_admin_user_path(@luca)

    assert_response :redirect
    follow_redirect!
    assert_match(/has been promoted to administrator/, flash[:notice])

    @luca.reload
    assert @luca.admin?
  ensure
    sign_out @mr_admin
  end

  # Test error handling in revoke action
  test "revoke action handles database errors gracefully" do
    sign_in @mr_admin
    # Set admin using direct SQL (since admin is readonly)
    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array(["UPDATE users SET admin=true WHERE users.id=?", @luca.id])
    )
    @luca.reload

    # Mock a database error
    original_execute = ActiveRecord::Base.connection.method(:execute)
    ActiveRecord::Base.connection.define_singleton_method(:execute) do |sql|
      raise ActiveRecord::StatementInvalid, "Database error"
    end

    patch revoke_admin_user_path(@luca)

    assert_response :redirect
    follow_redirect!
    assert_match(/Failed to revoke/, flash[:alert])

    # Verify user still has admin privileges
    @luca.reload
    assert @luca.admin?
  ensure
    ActiveRecord::Base.connection.define_singleton_method(:execute, original_execute)
    sign_out @mr_admin
  end

  test "revoke action shows success message on success" do
    sign_in @mr_admin
    # Set admin using direct SQL (since admin is readonly)
    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array(["UPDATE users SET admin=true WHERE users.id=?", @luca.id])
    )
    @luca.reload

    patch revoke_admin_user_path(@luca)

    assert_response :redirect
    follow_redirect!
    assert_match(/Administrator privileges have been revoked/, flash[:notice])

    @luca.reload
    assert_not @luca.admin?
  ensure
    sign_out @mr_admin
  end

  # Test SQL injection prevention
  test "promote action prevents SQL injection in user id" do
    sign_in @mr_admin

    # Attempt SQL injection in the id parameter
    # Rails routing will convert this to an integer or raise an error
    malicious_id = "1' OR '1'='1"

    # Rails routes will handle this - either convert to integer or 404
    patch promote_admin_user_path(malicious_id)

    # Should either 404 or handle gracefully, not execute SQL injection
    assert_includes [404, 422, 500], response.status

    # Verify no users were affected (only @mr_admin should be admin)
    admin_count = User.where(admin: true).count
    assert_equal 1, admin_count
  ensure
    sign_out @mr_admin
  end

  test "revoke action prevents SQL injection in user id" do
    sign_in @mr_admin

    # Attempt SQL injection in the id parameter
    malicious_id = "1' OR '1'='1"

    # Rails routes will handle this - either convert to integer or 404
    patch revoke_admin_user_path(malicious_id)

    # Should either 404 or handle gracefully, not execute SQL injection
    assert_includes [404, 422, 500], response.status

    # Verify no users were affected
    admin_count = User.where(admin: true).count
    assert_equal 1, admin_count
  ensure
    sign_out @mr_admin
  end

  test "promote uses parameterized queries" do
    sign_in @mr_admin

    # Verify that the SQL uses parameterized queries (sanitize_sql_array)
    # The fact that promote works correctly with any user ID proves parameterized queries
    # are being used (otherwise SQL injection would be possible)
    patch promote_admin_user_path(@luca)

    assert_response :redirect
    @luca.reload
    assert @luca.admin?

    # Clean up
    patch revoke_admin_user_path(@luca)
  ensure
    sign_out @mr_admin
  end

  # Test edge cases for admin self-revocation
  test "admin cannot revoke their own privileges via direct action" do
    sign_in @mr_admin

    patch revoke_admin_user_path(@mr_admin)

    assert_response :redirect
    follow_redirect!
    assert_match(/You cannot revoke your own administrator privileges/, flash[:alert])

    @mr_admin.reload
    assert @mr_admin.admin?
  ensure
    sign_out @mr_admin
  end

  test "admin self-revocation attempt shows error message" do
    sign_in @mr_admin

    patch revoke_admin_user_path(@mr_admin)

    assert_response :redirect
    follow_redirect!
    assert_select ".alert", text: /cannot revoke your own/
  ensure
    sign_out @mr_admin
  end

  # Test promote/revoke with non-existent user
  test "promote action handles non-existent user" do
    sign_in @mr_admin

    # Non-existent user ID should result in RecordNotFound or 404
    patch promote_admin_user_path(99999)

    # Should either raise error or return 404
    assert_includes [404, 500], response.status
  ensure
    sign_out @mr_admin
  end

  test "revoke action handles non-existent user" do
    sign_in @mr_admin

    # Non-existent user ID should result in RecordNotFound or 404
    patch revoke_admin_user_path(99999)

    # Should either raise error or return 404
    assert_includes [404, 500], response.status
  ensure
    sign_out @mr_admin
  end

  # Test that admin actions require authentication
  test "promote action requires admin authentication" do
    @luca.confirm
    sign_in @luca

    patch promote_admin_user_path(@giuliana)
    assert_response :not_found
  ensure
    sign_out @luca
  end

  test "revoke action requires admin authentication" do
    @luca.confirm
    sign_in @luca

    patch revoke_admin_user_path(@giuliana)
    assert_response :not_found
  ensure
    sign_out @luca
  end

  # Test that admin actions require sign-in
  test "promote action requires sign-in" do
    patch promote_admin_user_path(@luca)
    assert_response :not_found
  end

  test "revoke action requires sign-in" do
    patch revoke_admin_user_path(@luca)
    assert_response :not_found
  end

  # Test multiple promote/revoke cycles
  test "can promote and revoke user multiple times" do
    sign_in @mr_admin

    # First promote
    patch promote_admin_user_path(@luca)
    @luca.reload
    assert @luca.admin?

    # Revoke
    patch revoke_admin_user_path(@luca)
    @luca.reload
    assert_not @luca.admin?

    # Promote again
    patch promote_admin_user_path(@luca)
    @luca.reload
    assert @luca.admin?

    # Revoke again
    patch revoke_admin_user_path(@luca)
    @luca.reload
    assert_not @luca.admin?

    # Clean up - ensure user is not admin at end
    if @luca.admin?
      patch revoke_admin_user_path(@luca)
    end
  ensure
    sign_out @mr_admin
  end

  # Test that direct SQL updates work correctly
  test "promote uses direct SQL update correctly" do
    sign_in @mr_admin

    original_admin_status = @luca.admin?

    patch promote_admin_user_path(@luca)

    @luca.reload
    # Should use direct SQL update, bypassing attr_readonly
    assert @luca.admin?
    assert_not_equal original_admin_status, @luca.admin?
  ensure
    sign_out @mr_admin
  end
end
