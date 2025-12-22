# frozen_string_literal: true

require "application_system_test_case"

class AdminUserDeletionTest < ApplicationSystemTestCase
  setup do
    Settings.enable_logins = true
    Rails.application.reload_routes!

    @mr_admin = users(:mr_admin)
    @luca = users(:luca)
    @luca.confirm
    @giuliana = users(:giuliana)
    @giuliana.confirm

    login_as(@mr_admin, scope: :user)
  end

  teardown do
    logout(:user)
    Settings.enable_logins = false
    Rails.application.reload_routes!
  end

  test "delete button is visible for non-current-user admin accounts" do
    visit admin_users_path

    # Promote @luca to admin first
    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array(["UPDATE users SET admin=true WHERE users.id=?", @luca.id])
    )

    visit admin_users_path

    # Look for the delete button in the admin users table
    # Find first table (admin users table)
    first_table = all("table").first
    within(first_table) do
      row = find("tr", text: @luca.email)
      within(row) do
        assert_selector "button.btn-outline-danger", text: "Delete"
      end
    end
  end

  test "delete button has confirmation warning on admin users page" do
    visit admin_users_path

    # Find the delete button for @luca
    row = find("tr", text: @luca.email)
    within(row) do
      delete_form = find("form[action='#{admin_user_path(@luca)}']")
      assert delete_form["data-turbo-confirm"].present? || delete_form.find("button")["data-turbo-confirm"].present?,
        "Delete button or form should have data-turbo-confirm attribute"
    end
  end

  test "admin cannot see delete button for their own account" do
    visit admin_users_path

    # Find the row with the current admin's email
    row = find("tr", text: @mr_admin.email)
    within(row) do
      # Should show plain text instead of delete button
      assert_no_selector "button.btn-outline-danger", text: "Delete"
      assert_selector "span.text-muted.small", text: "Your Account"
    end
  end

  # /admin/dbexplore/users page tests (madmin)

  test "delete button is visible on madmin users index page" do
    visit madmin_users_path

    # Find row with @luca's email
    row = find("tr", text: @luca.email)
    within(row) do
      assert_selector "button", text: "Delete"
    end
  end

  test "delete button has confirmation warning on madmin users index" do
    visit madmin_users_path

    row = find("tr", text: @luca.email)
    within(row) do
      delete_form = find("form[method='post']", text: "Delete")
      # Check if form or button has turbo_confirm attribute
      has_confirm = delete_form["data-turbo-confirm"].present? ||
        (delete_form.has_selector?("button") && delete_form.find("button")["data-turbo-confirm"].present?)
      assert has_confirm, "Delete form should have data-turbo-confirm attribute"
    end
  end

  test "admin cannot see delete button for their own account on madmin" do
    visit madmin_users_path

    # Find row with current admin's email
    row = find("tr", text: @mr_admin.email)
    within(row) do
      # Should show plain text instead of delete button
      assert_no_selector "button", text: "Delete"
      assert_selector "span.text-muted.small", text: "Your Account"
    end
  end
end
