# frozen_string_literal: true

require "application_system_test_case"

class MadminLocalTimeTest < ApplicationSystemTestCase
  setup do
    Rails.application.reload_routes!

    @mr_admin = users(:mr_admin)
    @giuliana = users(:giuliana)
    @test_push = pushes(:test_push)

    login_as(@mr_admin, scope: :user)
  end

  teardown do
    logout(:user)
    Rails.application.reload_routes!
  end

  test "madmin users index renders timestamps with local_time helper" do
    visit madmin_users_path

    # Verify the page loads successfully
    assert_selector "h1", text: "Users"

    # Find the row with giuliana's email and check that it has a time element
    # The local_time helper renders a <time> tag with data-local attribute
    row = find("tr", text: @giuliana.email)
    within(row) do
      # local_time renders a <time> tag with data-local="time" or data-local="date"
      assert_selector "time[data-local]", minimum: 1
    end
  end

  test "madmin users show page renders timestamps with local_time helper" do
    visit madmin_user_path(@giuliana)

    # Verify the page loads successfully
    assert_selector "h1", text: @giuliana.email

    # On the show page, we should see time elements for datetime fields
    # local_time helper generates <time> tags with data attributes
    assert_selector "time[data-local]", minimum: 1
  end

  test "madmin pushes index renders timestamps with local_time helper" do
    visit madmin_pushes_path

    # Verify the page loads successfully
    assert_selector "h1", text: "Pushes"

    # Find the push row and verify it has time elements
    assert_selector "time[data-local]", minimum: 1
  end

  test "madmin pushes show page renders timestamps with local_time helper" do
    visit madmin_push_path(@test_push)

    # Verify the page loads successfully - h1 contains the url_token for pushes
    assert_selector "h1", text: @test_push.url_token

    # Show page should have time elements for datetime fields
    assert_selector "time[data-local]", minimum: 1
  end

  test "madmin audit_logs index renders timestamps with local_time helper" do
    visit madmin_audit_logs_path

    # Verify the page loads successfully
    assert_selector "h1", text: "Audit Logs"

    # Audit logs should have time elements for their timestamps
    assert_selector "time[data-local]", minimum: 1
  end

  test "local_time renders proper data attributes" do
    visit madmin_users_path

    # Find giuliana's row
    row = find("tr", text: @giuliana.email)
    within(row) do
      # Look for the first time element (there may be multiple timestamps)
      time_element = first("time[data-local]")

      # Verify it has the proper data attributes that local_time sets
      assert time_element["data-local"].present?, "Time element should have data-local attribute"
      assert time_element["datetime"].present?, "Time element should have datetime attribute"

      # The datetime attribute should be in ISO8601 format
      datetime_value = time_element["datetime"]
      assert_match(/\d{4}-\d{2}-\d{2}/, datetime_value, "datetime attribute should contain date in ISO format")
    end
  end

  test "local_time handles nil values gracefully" do
    # Visit users page - some fields may be nil (like last_sign_in_at)
    visit madmin_users_path
    assert_selector "h1", text: "Users"

    # Page should load without errors even if some datetime fields are nil
    # Just verify the page loaded successfully by finding expected content
    assert_text @giuliana.email
  end
end
