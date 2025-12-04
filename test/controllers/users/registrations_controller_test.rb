# frozen_string_literal: true

require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    @user = users(:luca)
    @other_user = users(:one)
  end

  teardown do
    Settings.enable_logins = false
  end

  # DELETE /users (destroy action)

  test "authenticated user can delete their own account" do
    sign_in @user

    assert_difference("User.count", -1) do
      delete user_registration_path
    end

    assert_redirected_to root_path
  end

  test "unauthenticated user cannot delete account" do
    assert_no_difference("User.count") do
      delete user_registration_path
    end

    assert_redirected_to new_user_session_path
    assert_equal "You need to sign in or sign up before continuing.", flash[:alert]
  end

  test "user can only delete their own account" do
    sign_in @user

    # This test verifies that even if someone tried to manipulate the request,
    # they can only delete their own account (current_user)
    # Devise automatically uses current_user as the resource
    assert_difference("User.count", -1) do
      delete user_registration_path
    end

    # Verify the correct user was deleted
    assert_nil User.find_by(id: @user.id)
    assert_not_nil User.find_by(id: @other_user.id)
  end

  test "user is signed out after deleting account" do
    sign_in @user

    delete user_registration_path

    # Verify user is no longer signed in
    assert_nil controller.current_user
  end

  test "destroy requires DELETE method" do
    sign_in @user

    # Attempt with GET should not work
    assert_no_difference("User.count") do
      get user_registration_path
    end
  end
end
