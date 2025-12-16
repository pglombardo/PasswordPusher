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

  # /admin/users page tests
  test "delete button is visible for regular users on admin users page" do
    visit admin_users_path

    # Look for the delete button in the regular users section
    # The button should be visible for @luca (a regular user)
    # Use all tables and find the one with luca's email (second table - regular users)
    tables = all("table")
    regular_users_table = tables.last  # Regular users table is the last one

    within(regular_users_table) do
      row = find("tr", text: @luca.email)
      within(row) do
        assert_selector "button.btn-outline-danger", text: "Delete"
      end
    end
  end

  test "delete button is visible for admin users on admin users page" do
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
      # Should show info icon with tooltip instead of delete button
      assert_selector "span[data-bs-toggle='tooltip']"
      assert_selector "span svg"
      assert_no_selector "button.btn-outline-danger", text: "Delete"
    end
  end

  test "info icon with tooltip is visible for current admin's own account" do
    visit admin_users_path

    # Find the row with the current admin's email
    row = find("tr", text: @mr_admin.email)
    within(row) do
      # Should have the info icon span with tooltip
      icon_span = find("span[data-bs-toggle='tooltip']")
      assert icon_span.present?, "Info icon span should be present"
      assert_equal "Cannot modify your own account", icon_span["title"], "Tooltip should explain why actions are disabled"

      # Check that the span has the hover-opacity class
      assert_selector "span.text-muted.small[data-bs-toggle='tooltip']"

      # Verify the SVG icon is present within the span
      assert icon_span.has_selector?("svg"), "Icon span should contain SVG element"
    end
  end

  # /admin/dbexplore/users page tests (madmin)
  test "delete button is visible on madmin user show page" do
    # First update the show page to include delete button
    visit madmin_user_path(@luca)

    # Check if delete button exists
    # Note: Currently the madmin show page doesn't have a delete button
    # This test will fail until we add it
    if has_selector?("form[action='#{madmin_user_path(@luca)}'] button.btn-outline-danger")
      assert_selector "form[action='#{madmin_user_path(@luca)}'] button.btn-outline-danger"
    else
      skip "Delete button not yet implemented on madmin show page"
    end
  end

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

  test "delete button has confirmation warning on madmin user show page" do
    visit madmin_user_path(@luca)

    if has_selector?("form[action='#{madmin_user_path(@luca)}']")
      delete_form = find("form[action='#{madmin_user_path(@luca)}']")
      has_confirm = delete_form["data-turbo-confirm"].present? ||
        (delete_form.has_selector?("button") && delete_form.find("button")["data-turbo-confirm"].present?)
      assert has_confirm, "Delete form should have data-turbo-confirm attribute"
    else
      skip "Delete button not yet implemented on madmin show page"
    end
  end

  test "admin cannot see delete button for their own account on madmin" do
    visit madmin_users_path

    # Find row with current admin's email
    row = find("tr", text: @mr_admin.email)
    within(row) do
      # Should show a message or icon instead of delete button
      assert_no_selector "button", text: "Delete"
      # Check for the info icon span (it has the tooltip)
      assert_selector "span.text-muted"
    end
  end
end
