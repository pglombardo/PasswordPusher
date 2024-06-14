# frozen_string_literal: true

require "application_system_test_case"

class FilePushesTest < ApplicationSystemTestCase
  setup do
    @file_push = file_pushes(:one)
  end

  test "visiting the index" do
    visit file_pushes_url
    assert_selector "h1", text: "File pushes"
  end

  test "should create file push" do
    visit file_pushes_url
    click_on "New file push"

    check "Deletable by viewer" if @file_push.deletable_by_viewer
    check "Deleted" if @file_push.deleted
    fill_in "Expire after days", with: @file_push.expire_after_days
    fill_in "Expire after views", with: @file_push.expire_after_views
    check "Expired" if @file_push.expired
    fill_in "Expired on", with: @file_push.expired_on
    fill_in "Note", with: @file_push.note
    fill_in "Payload", with: @file_push.payload
    check "Retrieval step" if @file_push.retrieval_step
    fill_in "Url token", with: @file_push.url_token
    fill_in "User", with: @file_push.user_id
    click_on "Create File push"

    assert_text "File push was successfully created"
    click_on "Back"
  end

  test "should update File push" do
    visit file_push_url(@file_push)
    click_on "Edit this file push", match: :first

    check "Deletable by viewer" if @file_push.deletable_by_viewer
    check "Deleted" if @file_push.deleted
    fill_in "Expire after days", with: @file_push.expire_after_days
    fill_in "Expire after views", with: @file_push.expire_after_views
    check "Expired" if @file_push.expired
    fill_in "Expired on", with: @file_push.expired_on
    fill_in "Note", with: @file_push.note
    fill_in "Payload", with: @file_push.payload
    check "Retrieval step" if @file_push.retrieval_step
    fill_in "Url token", with: @file_push.url_token
    fill_in "User", with: @file_push.user_id
    click_on "Update File push"

    assert_text "File push was successfully updated"
    click_on "Back"
  end

  test "should destroy File push" do
    visit file_push_url(@file_push)
    click_on "Destroy this file push", match: :first

    assert_text "File push was successfully destroyed"
  end
end
