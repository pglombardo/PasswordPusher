# frozen_string_literal: true

require "application_system_test_case"

class UserAccountDeletionTest < ApplicationSystemTestCase
  setup do
    Settings.enable_logins = true
    Rails.application.reload_routes!

    @user = users(:luca)
    @user.confirm
    login_as(@user, scope: :user)
  end

  teardown do
    logout(:user)
    Settings.enable_logins = false
  end

  test "delete account button is visible on edit account page" do
    visit edit_user_registration_path

    # Verify the delete account section is present
    # The text can be "Delete my account" or "Cancel my account" depending on locale
    assert_text(/delete.*account|cancel.*account/i, wait: 5)

    # Verify the delete button is present with correct styling
    # Look for any submit button with the outline-danger class
    assert_selector ".btn-outline-danger", wait: 5
  end

  test "delete account button has confirmation dialog" do
    visit edit_user_registration_path

    # Find the delete button by class
    delete_button = find(".btn-outline-danger")

    # Verify it has the turbo_confirm data attribute
    assert delete_button["data-turbo-confirm"].present?
  end

  test "user can successfully delete their account" do
    visit edit_user_registration_path

    # Accept the confirmation dialog and click delete
    accept_confirm do
      click_button class: "btn-outline-danger"
    end

    # Should redirect to root path after deletion
    assert_current_path root_path, wait: 5

    # Verify user is logged out
    visit edit_user_registration_path
    assert_current_path new_user_session_path, wait: 5
  end

  test "delete account section appears after verification section" do
    visit edit_user_registration_path

    # Get all section headers
    sections = all("p.lead")
    section_texts = sections.map(&:text)

    # Verify delete account section exists (can be "Delete" or "Cancel" depending on locale)
    assert section_texts.any? { |text| text.match?(/delete.*account|cancel.*account/i) }

    # Find the index of verification and delete sections
    verification_index = section_texts.find_index { |text| text.match?(/verification/i) }
    delete_index = section_texts.find_index { |text| text.match?(/delete.*account|cancel.*account/i) }

    # Delete section should come after verification
    assert delete_index, "Delete account section not found"
    assert verification_index, "Verification section not found"
    assert delete_index > verification_index, "Delete account section should come after verification section"
  end

  test "anonymous user cannot see delete account button" do
    logout(:user)

    # Try to visit edit account page
    visit edit_user_registration_path

    # Should be redirected to sign in
    assert_current_path new_user_session_path, wait: 5

    # Delete button should not be present
    assert_no_selector ".btn-outline-danger"
  end
end
