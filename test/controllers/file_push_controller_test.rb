# frozen_string_literal: true

require "test_helper"

class FilePushControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!
  end

  teardown do
    @luca = users(:luca)
    sign_out @luca
  end

  test "New push form is NOT available anonymous" do
    get new_push_path(tab: "files")
    assert_redirected_to new_user_session_path
  end

  test '"index" should redirect anonymous to user sign in' do
    get pushes_path
    assert_response :redirect
    follow_redirect!
    assert response.body.include?("You need to sign in or sign up before continuing.")
  end

  test "logged in users can access their dashboard" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    get pushes_path
    assert_response :success
    assert response.body.include?("You currently have no pushes.")

    get pushes_path(filter: "active")
    assert_response :success
    assert response.body.include?("You currently have no active pushes.")

    get pushes_path(filter: "expired")
    assert_response :success
    assert response.body.include?("You currently have no expired pushes.")
  end

  test "logged in users with pushes can access their dashboard" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    no_push_text = "You currently have no pushes."
    get pushes_path
    assert_response :success
    assert response.body.include?(no_push_text)

    get new_push_path(tab: "files")
    assert_response :success
    assert response.body.include?("You can upload up to")

    post pushes_path params: {
      push: {
        kind: "file",
        payload: "TWVycnkgQ2hyaXN0bWFzIDIwMjIgdG8gbXkgYmVhdXRpZnVsIGdpcmxzIExlYSAmIEdpdWxpYW5hLiAgSSBsb3ZlIHlvdS4gIFBhcGE="
      }
    }
    assert_response :redirect

    get pushes_path
    assert_response :success
    assert_not response.body.include?(no_push_text)
  end

  test "get active dashboard with token" do
    @luca = users(:luca)
    @luca.confirm

    get active_file_pushes_path(format: :json), headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success
  end

  test "get expired dashboard with token" do
    @luca = users(:luca)
    @luca.confirm

    get expired_file_pushes_path(format: :json), headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success
  end

  test "override base url" do
    Settings.override_base_url = "https://example.com:12345"

    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    post pushes_path params: {
      push: {
        kind: "file",
        payload: "TWVycnkgQ2hyaXN0bWFzIDIwMjIgdG8gbXkgYmVhdXRpZnVsIGdpcmxzIExlYSAmIEdpdWxpYW5hLg=="
      }
    }
    assert_response :redirect

    follow_redirect!
    assert_response :success

    assert response.body.include?("https://example.com:12345")
  end

  test "logged in user can edit their file push" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    # Create a file push
    push = Push.create!(
      kind: "file",
      name: "Original Name",
      user: @luca
    )
    file = fixture_file_upload("test-file.txt", "text/plain")
    push.files.attach(file)

    # Access edit page
    get edit_push_path(push)
    assert_response :success
    assert response.body.include?("Editing Push")
    assert response.body.include?(push.url_token)
    assert response.body.include?("Uploaded Files")
    assert response.body.include?("test-file.txt")

    # Update the push
    patch push_path(push), params: {
      push: {
        name: "Updated Name",
        expire_after_days: 10,
        expire_after_views: 5
      }
    }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    push.reload
    assert_equal "Updated Name", push.name
    assert_equal 10, push.expire_after_days
    assert_equal 5, push.expire_after_views
    assert_equal 1, push.files.count, "Files should be preserved when updating other attributes"
  end

  test "logged in user cannot edit another user's file push" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    # Create a push for a different user
    other_user = User.create!(
      email: "other@example.com",
      password: "password123",
      confirmed_at: Time.current
    )
    push = Push.create!(
      kind: "file",
      user: other_user
    )

    # Try to access edit page
    get edit_push_path(push)
    assert_response :redirect
    follow_redirect!
    assert_match(/That push doesn&#39;t belong to you/, response.body)
  end

  test "cannot edit expired file push" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    # Create an expired push
    push = Push.create!(
      kind: "file",
      user: @luca,
      expired: true
    )

    # Try to access edit page
    get edit_push_path(push)
    assert_response :redirect
    follow_redirect!
    assert response.body.include?("That push has already expired and cannot be edited.")
  end

  test "updating file push without new files preserves existing files" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    # Create a file push with files
    push = Push.create!(
      kind: "file",
      name: "Test Push",
      user: @luca
    )
    file1 = fixture_file_upload("test-file.txt", "text/plain")
    file2 = fixture_file_upload("test-file-2.txt", "text/plain")
    push.files.attach([file1, file2])
    assert_equal 2, push.files.count

    # Update push without touching files
    patch push_path(push), params: {
      push: {
        name: "Updated Test Push",
        expire_after_days: 7
      }
    }
    assert_response :redirect

    push.reload
    assert_equal "Updated Test Push", push.name
    assert_equal 7, push.expire_after_days
    assert_equal 2, push.files.count, "Existing files should be preserved"
  end

  test "adding new files appends to existing files" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    # Create a file push with one file
    push = Push.create!(
      kind: "file",
      name: "Test Push",
      user: @luca
    )
    file1 = fixture_file_upload("test-file.txt", "text/plain")
    push.files.attach(file1)
    assert_equal 1, push.files.count

    # Add another file via update
    patch push_path(push), params: {
      push: {
        files: [fixture_file_upload("test-file-2.txt", "text/plain")]
      }
    }
    assert_response :redirect

    push.reload
    assert_equal 2, push.files.count, "New files should be appended to existing files"
    filenames = push.files.map(&:filename).map(&:to_s)
    assert_includes filenames, "test-file.txt"
    assert_includes filenames, "test-file-2.txt"
  end

  test "can delete individual file when multiple files exist" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    # Create a file push with multiple files
    push = Push.create!(
      kind: "file",
      user: @luca
    )
    file1 = fixture_file_upload("test-file.txt", "text/plain")
    file2 = fixture_file_upload("test-file-2.txt", "text/plain")
    push.files.attach([file1, file2])
    assert_equal 2, push.files.count

    # Delete one file
    file_to_delete = push.files.first
    delete delete_file_push_path(push, file_id: file_to_delete.id)
    assert_response :redirect
    follow_redirect!
    assert response.body.include?("File was successfully deleted")

    push.reload
    assert_equal 1, push.files.count
  end

  test "cannot delete last file from file push" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    # Create a file push with one file
    push = Push.create!(
      kind: "file",
      user: @luca
    )
    file = fixture_file_upload("test-file.txt", "text/plain")
    push.files.attach(file)
    assert_equal 1, push.files.count

    # Try to delete the last file
    file_to_delete = push.files.first
    delete delete_file_push_path(push, file_id: file_to_delete.id)
    assert_response :redirect
    follow_redirect!
    assert response.body.include?("You cannot delete the last file from a file push")

    push.reload
    assert_equal 1, push.files.count, "File should not be deleted"
  end

  test "cannot delete file from another user's push" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    # Create a push for a different user
    other_user = User.create!(
      email: "other2@example.com",
      password: "password123",
      confirmed_at: Time.current
    )
    push = Push.create!(
      kind: "file",
      user: other_user
    )
    file = fixture_file_upload("test-file.txt", "text/plain")
    push.files.attach(file)

    # Try to delete file
    file_to_delete = push.files.first
    delete delete_file_push_path(push, file_id: file_to_delete.id)
    assert_response :redirect
    follow_redirect!
    assert_match(/That push doesn&#39;t belong to you/, response.body)
  end

  test "checkboxes are saved when creating a push" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    push = Push.create!(
      kind: "file",
      user: @luca,
      retrieval_step: true,
      deletable_by_viewer: true
    )
    file = fixture_file_upload("test-file.txt", "text/plain")
    push.files.attach(file)

    assert push.retrieval_step, "retrieval_step should be true"
    assert push.deletable_by_viewer, "deletable_by_viewer should be true"
  end

  test "checkboxes are saved when editing a push" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    push = Push.create!(
      kind: "file",
      user: @luca,
      retrieval_step: false,
      deletable_by_viewer: false
    )
    file = fixture_file_upload("test-file.txt", "text/plain")
    push.files.attach(file)

    patch push_path(push), params: {
      push: {
        retrieval_step: "1",
        deletable_by_viewer: "1"
      }
    }
    assert_response :redirect

    push.reload
    assert push.retrieval_step, "retrieval_step should be true after update"
    assert push.deletable_by_viewer, "deletable_by_viewer should be true after update"
  end

  test "unchecked checkboxes are saved as false when editing" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    push = Push.create!(
      kind: "file",
      user: @luca,
      retrieval_step: true,
      deletable_by_viewer: true
    )
    file = fixture_file_upload("test-file.txt", "text/plain")
    push.files.attach(file)

    # When unchecked, HTML forms don't send the parameter at all
    patch push_path(push), params: {
      push: {
        payload: "updated"
      }
    }
    assert_response :redirect

    push.reload
    assert_not push.retrieval_step, "retrieval_step should be false after unchecking"
    assert_not push.deletable_by_viewer, "deletable_by_viewer should be false after unchecking"
  end
end
