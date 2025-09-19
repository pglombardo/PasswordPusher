# frozen_string_literal: true

require "test_helper"

class AdminUsersTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Rails.application.reload_routes!
    @admin = users(:mr_admin)
    sign_in @admin
  end

  teardown do
    Settings.enable_logins = false
    Rails.application.reload_routes!
    sign_out @admin
  end

  test "admin can access user creation form" do
    get "/admin/users/new"
    assert_response :success
    assert_select "form" # Ensure form is present
  end

  test "admin user creation with valid data succeeds" do
    assert_difference "User.count", 1 do
      post "/admin/users", params: {
        user: {
          email: "newuser@example.com",
          password: "validpassword123",
          password_confirmation: "validpassword123"
        }
      }
    end
    
    # Should redirect on success (typical for successful creates)
    assert_redirected_to admin_user_path(User.last)
    follow_redirect!
    assert_response :success
  end

  test "admin user creation with invalid password returns form with errors" do
    assert_no_difference "User.count" do
      post "/admin/users", params: {
        user: {
          email: "invaliduser@example.com",
          password: "123456", # Too short - should trigger validation error
          password_confirmation: "123456"
        }
      }
    end
    
    # Should render the form again with validation errors (not a 500 error)
    assert_response :success
    assert_select ".field_with_errors", minimum: 1 # Should show field errors
    # The key fix: no more 500 errors, should show validation messages
  end

  test "admin user creation with invalid email returns form with errors" do
    assert_no_difference "User.count" do
      post "/admin/users", params: {
        user: {
          email: "invalid-email", # Invalid email format
          password: "validpassword123",
          password_confirmation: "validpassword123"
        }
      }
    end
    
    # Should render the form again with validation errors (not a 500 error)
    assert_response :success
    assert_select ".field_with_errors", minimum: 1 # Should show field errors
  end

  test "admin user creation with duplicate email returns form with errors" do
    # Create a user first
    existing_user = User.create!(
      email: "existing@example.com",
      password: "validpassword123", 
      password_confirmation: "validpassword123"
    )
    existing_user.confirm
    
    assert_no_difference "User.count" do
      post "/admin/users", params: {
        user: {
          email: "existing@example.com", # Duplicate email
          password: "validpassword123",
          password_confirmation: "validpassword123"
        }
      }
    end
    
    # Should render the form again with validation errors (not a 500 error)
    assert_response :success
    assert_select ".field_with_errors", minimum: 1 # Should show field errors
  end
end