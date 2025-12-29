# frozen_string_literal: true

require "test_helper"

module Madmin
  class UsersControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    def setup
      Settings.enable_logins = true
      Rails.application.reload_routes!

      @mr_admin = users(:mr_admin)
      @luca = users(:luca)
      @luca.confirm
      @giuliana = users(:giuliana)
      @giuliana.confirm

      sign_in @mr_admin
    end

    def teardown
      sign_out @mr_admin
      Settings.enable_logins = false
      Rails.application.reload_routes!
    end

    test "admin can delete another user via madmin" do
      assert_difference("User.count", -1) do
        delete madmin_user_path(@luca)
      end

      assert_redirected_to madmin_users_path
      follow_redirect!
      assert_equal "User #{@luca.email} has been deleted.", flash[:notice]
    end

    test "deleting user via madmin also deletes their pushes" do
      3.times do
        Push.create!(
          kind: :text,
          payload: "Test",
          user: @luca,
          expire_after_days: 7,
          expire_after_views: 10
        )
      end
      @luca.reload

      initial_push_count = Push.count
      user_push_count = @luca.pushes.count

      delete madmin_user_path(@luca)

      assert_equal initial_push_count - user_push_count, Push.count
    end

    test "admin cannot delete their own account via madmin" do
      assert_no_difference("User.count") do
        delete madmin_user_path(@mr_admin)
      end

      assert_redirected_to madmin_users_path
      follow_redirect!
      assert_match(/cannot delete your own account/i, flash[:alert])
    end

    test "non-admin cannot delete users via madmin" do
      sign_out @mr_admin
      sign_in @luca

      delete madmin_user_path(@giuliana)

      # Non-admins don't have access to madmin routes (404)
      assert_response 404
    end

    test "unauthenticated user cannot delete users via madmin" do
      sign_out @mr_admin

      delete madmin_user_path(@luca)

      # Unauthenticated users get 404 on madmin routes
      assert_response 404
    end
  end
end
