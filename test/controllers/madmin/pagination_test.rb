# frozen_string_literal: true

require "test_helper"

module Madmin
  class PaginationTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      sign_in users(:mr_admin)
    end

    test "users index summarizes the current page" do
      get madmin_users_path

      assert_response :success
      shown = [User.count, Madmin.per_page].min
      assert_select ".pagination-info", text: "Displaying 1-#{shown} of #{User.count}"
      assert_select "nav[aria-label=?]", "Pagination", count: ((User.count > Madmin.per_page) ? 1 : 0)
    end

    test "users index paginates with the madmin page object" do
      get madmin_users_path(per_page: 2)

      assert_response :success
      assert_select ".pagination-info", text: "Displaying 1-2 of #{User.count}"
      assert_select "nav[aria-label=?]", "Pagination" do
        assert_select "a.page-link[href=?]", madmin_users_path(page: 2, per_page: 2)
        assert_select "span.page-link[aria-hidden]", text: "<"
      end

      get madmin_users_path(page: 2, per_page: 2)

      assert_response :success
      assert_select ".pagination-info", text: "Displaying 3-4 of #{User.count}"
      assert_select "li.page-item.active", text: "2"
      assert_select "a.page-link[href=?]", madmin_users_path(page: 1, per_page: 2), text: "<"
      assert_select "a.page-link[href=?]", madmin_users_path(page: 3, per_page: 2), text: ">"
    end

    test "shared resource index paginates with the madmin page object" do
      get madmin_audit_logs_path(per_page: 2)

      assert_response :success
      assert_select ".pagination-info", text: "Displaying 1-2 of #{AuditLog.count}"
      assert_select "nav[aria-label=?]", "Pagination" do
        assert_select "a.page-link[href=?]", madmin_audit_logs_path(page: 2, per_page: 2)
      end

      get madmin_audit_logs_path(page: 2, per_page: 2)

      assert_response :success
      assert_select ".pagination-info", text: "Displaying 3-4 of #{AuditLog.count}"
      assert_select "li.page-item.active", text: "2"
    end

    test "customized show and form templates render" do
      user = users(:luca)
      push = pushes(:test_push)

      get madmin_user_path(user)
      assert_response :success
      assert_select "h1", text: user.email

      get new_madmin_user_path
      assert_response :success

      get madmin_push_path(push)
      assert_response :success

      get edit_madmin_push_path(push)
      assert_response :success

      get madmin_audit_log_path(audit_logs(:creation))
      assert_response :success
    end

    test "empty resource index shows an empty pagination summary" do
      assert_equal 0, ::ActiveStorage::VariantRecord.count

      get madmin_active_storage_variant_records_path

      assert_response :success
      assert_select ".pagination-info", text: "No records found"
      assert_select "nav[aria-label=?]", "Pagination", count: 0
    end
  end
end
