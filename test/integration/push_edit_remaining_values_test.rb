# frozen_string_literal: true

require "test_helper"

class PushEditRemainingValuesTest < ActionDispatch::IntegrationTest
  setup do
    Settings.enable_logins = true
    Settings.enable_url_pushes = true
    Settings.enable_file_pushes = true
    Settings.enable_qr_pushes = true

    @user = users(:luca)
    sign_in @user
  end

  test "text push edit form shows remaining days not original days" do
    # Create a push that expires in 7 days
    push = Push.create!(
      kind: "text",
      payload: "test password",
      user: @user,
      expire_after_days: 7,
      expire_after_views: 10
    )

    # Simulate the push being 3 days old
    push.update_column(:created_at, 3.days.ago)

    get edit_push_path(push)
    assert_response :success

    # Verify remaining days (7 - 3 = 4)
    assert_select "input#push_expire_after_days[value='4']"
    assert_select "[data-knobs-target='daysRangeLabel']", text: /4/
  end

  test "text push edit form shows remaining views not original views" do
    # Create a push that expires after 10 views
    push = Push.create!(
      kind: "text",
      payload: "test password",
      user: @user,
      expire_after_days: 7,
      expire_after_views: 10
    )

    # Simulate 3 views
    3.times do
      AuditLog.create!(push: push, kind: :view, ip: "1.2.3.4", user_agent: "Test")
    end

    get edit_push_path(push)
    assert_response :success

    # Verify remaining views (10 - 3 = 7)
    assert_select "input#push_expire_after_views[value='7']"
    assert_select "[data-knobs-target='viewsRangeLabel']", text: /7/
  end

  test "text push edit form data attributes use remaining values" do
    push = Push.create!(
      kind: "text",
      payload: "test password",
      user: @user,
      expire_after_days: 10,
      expire_after_views: 15
    )

    # Simulate 5 days old and 5 views
    push.update_column(:created_at, 5.days.ago)
    5.times do
      AuditLog.create!(push: push, kind: :view, ip: "1.2.3.4", user_agent: "Test")
    end

    get edit_push_path(push)
    assert_response :success

    # Verify data attributes show remaining values (5 days, 10 views)
    assert_select "[data-knobs-default-days-value='5']"
    assert_select "[data-knobs-default-views-value='10']"
  end

  test "url push edit form shows remaining days and views" do
    push = Push.create!(
      kind: "url",
      payload: "https://example.com",
      user: @user,
      expire_after_days: 14,
      expire_after_views: 20
    )

    # Simulate 7 days old and 10 views
    push.update_column(:created_at, 7.days.ago)
    10.times do
      AuditLog.create!(push: push, kind: :view, ip: "1.2.3.4", user_agent: "Test")
    end

    get edit_push_path(push)
    assert_response :success

    # Verify remaining values (7 days, 10 views)
    assert_select "input#push_expire_after_days[value='7']"
    assert_select "input#push_expire_after_views[value='10']"
    assert_select "[data-knobs-target='daysRangeLabel']", text: /7/
    assert_select "[data-knobs-target='viewsRangeLabel']", text: /10/
  end

  test "file push edit form shows remaining days and views" do
    push = Push.create!(
      kind: "file",
      user: @user,
      expire_after_days: 30,
      expire_after_views: 50
    )

    push.files.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test-file.txt")),
      filename: "test-file.txt",
      content_type: "text/plain"
    )

    # Simulate 10 days old and 20 views
    push.update_column(:created_at, 10.days.ago)
    20.times do
      AuditLog.create!(push: push, kind: :view, ip: "1.2.3.4", user_agent: "Test")
    end

    get edit_push_path(push)
    assert_response :success

    # Verify remaining values (20 days, 30 views)
    assert_select "input#push_expire_after_days[value='20']"
    assert_select "input#push_expire_after_views[value='30']"
    assert_select "[data-knobs-target='daysRangeLabel']", text: /20/
    assert_select "[data-knobs-target='viewsRangeLabel']", text: /30/
  end

  test "qr push edit form shows remaining days and views" do
    push = Push.create!(
      kind: "qr",
      payload: "QR content here",
      user: @user,
      expire_after_days: 5,
      expire_after_views: 8
    )

    # Simulate 2 days old and 3 views
    push.update_column(:created_at, 2.days.ago)
    3.times do
      AuditLog.create!(push: push, kind: :view, ip: "1.2.3.4", user_agent: "Test")
    end

    get edit_push_path(push)
    assert_response :success

    # Verify remaining values (3 days, 5 views)
    assert_select "input#push_expire_after_days[value='3']"
    assert_select "input#push_expire_after_views[value='5']"
    assert_select "[data-knobs-target='daysRangeLabel']", text: /3/
    assert_select "[data-knobs-target='viewsRangeLabel']", text: /5/
  end

  test "edit form shows zero when days have expired" do
    push = Push.create!(
      kind: "text",
      payload: "test password",
      user: @user,
      expire_after_days: 5,
      expire_after_views: 10
    )

    # Simulate push being 10 days old (expired)
    push.update_column(:created_at, 10.days.ago)

    get edit_push_path(push)
    assert_response :success

    # Should show 0 days remaining
    assert_select "input#push_expire_after_days[value='0']"
    assert_select "[data-knobs-target='daysRangeLabel']", text: /0/
  end

  test "edit form shows zero when views have exceeded limit" do
    push = Push.create!(
      kind: "text",
      payload: "test password",
      user: @user,
      expire_after_days: 7,
      expire_after_views: 5
    )

    # Simulate 10 views (more than the limit)
    10.times do
      AuditLog.create!(push: push, kind: :view, ip: "1.2.3.4", user_agent: "Test")
    end

    get edit_push_path(push)
    assert_response :success

    # Should show 0 views remaining
    assert_select "input#push_expire_after_views[value='0']"
    assert_select "[data-knobs-target='viewsRangeLabel']", text: /0/
  end

  test "new push form shows default values not remaining values" do
    # Verify that new forms don't use remaining values logic
    get new_push_path(tab: "text")
    assert_response :success

    # Should show default values from settings
    default_days = Settings.pw.expire_after_days_default
    default_views = Settings.pw.expire_after_views_default

    assert_select "input#push_expire_after_days[value='#{default_days}']"
    assert_select "input#push_expire_after_views[value='#{default_views}']"
  end

  test "failed views are counted when calculating remaining views" do
    push = Push.create!(
      kind: "text",
      payload: "test password",
      user: @user,
      expire_after_days: 7,
      expire_after_views: 10
    )

    # Create a mix of successful and failed views
    3.times do
      AuditLog.create!(push: push, kind: :view, ip: "1.2.3.4", user_agent: "Test")
    end
    2.times do
      AuditLog.create!(push: push, kind: :failed_view, ip: "1.2.3.4", user_agent: "Test")
    end

    get edit_push_path(push)
    assert_response :success

    # Total views = 5 (3 successful + 2 failed), remaining = 10 - 5 = 5
    assert_select "input#push_expire_after_views[value='5']"
    assert_select "[data-knobs-target='viewsRangeLabel']", text: /5/
  end

  test "updating push with remaining values extends expiration correctly" do
    push = Push.create!(
      kind: "text",
      payload: "test password",
      user: @user,
      expire_after_days: 7,
      expire_after_views: 10
    )

    # Simulate 3 days old
    push.update_column(:created_at, 3.days.ago)

    # Edit and extend by changing remaining 4 days to 5 days
    patch push_path(push), params: {
      push: {
        payload: "updated password",
        expire_after_days: 5,
        expire_after_views: 10
      }
    }

    push.reload
    assert_equal 5, push.expire_after_days, "Should update to new value"
  end
end
