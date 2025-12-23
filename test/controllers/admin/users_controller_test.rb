# frozen_string_literal: true

require "test_helper"

module Admin
  class UsersControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      Settings.enable_logins = true
      Rails.application.reload_routes!

      @mr_admin = users(:mr_admin)
      @luca = users(:luca)
      @luca.confirm
      @giuliana = users(:giuliana)
      @giuliana.confirm

      sign_in @mr_admin
    end

    teardown do
      sign_out @mr_admin
      Settings.enable_logins = false
      Rails.application.reload_routes!
    end

    # Destroy action tests
    test "admin can delete another user" do
      assert_difference("User.count", -1) do
        delete admin_user_path(@luca)
      end

      assert_redirected_to admin_users_path
      follow_redirect!
      assert_equal "User #{@luca.email} has been deleted.", flash[:notice]
    end

    test "deleting user also deletes their pushes" do
      # Create some pushes for the user
      3.times do
        Push.create!(
          kind: :text,
          payload: "Test password",
          user: @luca,
          expire_after_days: 7,
          expire_after_views: 10
        )
      end
      @luca.reload

      initial_push_count = Push.count
      user_push_count = @luca.pushes.count

      assert user_push_count > 0, "User should have pushes before deletion"

      delete admin_user_path(@luca)

      assert_equal initial_push_count - user_push_count, Push.count, "All user's pushes should be deleted"
    end

    test "admin cannot delete their own account" do
      assert_no_difference("User.count") do
        delete admin_user_path(@mr_admin)
      end

      assert_redirected_to admin_users_path
      follow_redirect!
      assert_match(/cannot delete your own account/i, flash[:alert])
    end

    test "non-admin cannot access destroy action" do
      sign_out @mr_admin
      sign_in @luca

      delete admin_user_path(@giuliana)

      # Non-admins don't have access to admin routes at all (404)
      assert_response 404
    end

    test "unauthenticated user cannot delete users" do
      sign_out @mr_admin

      delete admin_user_path(@luca)

      # Unauthenticated users get 404 on admin routes
      assert_response 404
    end

    test "destroy requires DELETE method" do
      sign_in @mr_admin

      get admin_user_path(@luca)

      # GET on user path is not defined (only DELETE is)
      assert_response 404
      assert @luca.reload.present?, "User should not be deleted by GET request"
    end
  end
end
