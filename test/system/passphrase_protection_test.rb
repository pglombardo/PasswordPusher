# frozen_string_literal: true

require "application_system_test_case"

class PassphraseProtectionTest < ApplicationSystemTestCase
  setup do
    Settings.enable_logins = true
    Settings.enable_password_pushes = true
    Rails.application.reload_routes!

    @push = pushes(:test_push)
    @push.update(
      payload: "ProtectedSecret",
      passphrase: "correctpass",
      expired: false
    )
  end

  test "entering correct passphrase grants access" do
    visit push_path(@push)

    # Should redirect to passphrase page
    assert_current_path passphrase_push_path(@push)
    assert_selector "input[name='passphrase']"

    # Enter correct passphrase
    fill_in "passphrase", with: "correctpass"
    click_button "Go"

    # Should redirect to push page and show content
    assert_current_path push_path(@push)
    assert_text "ProtectedSecret"
  end

  test "entering incorrect passphrase shows error" do
    visit push_path(@push)

    # Should be on passphrase page
    assert_current_path passphrase_push_path(@push)

    # Enter incorrect passphrase
    fill_in "passphrase", with: "wrongpass"
    click_button "Go"

    # Should show error message and stay on passphrase page
    assert_current_path passphrase_push_path(@push)
    assert_text "incorrect"
    assert_text "try again"
  end

  test "passphrase cookie does not persist for subsequent views" do
    visit push_path(@push)

    # Enter correct passphrase
    fill_in "passphrase", with: "correctpass"
    click_button "Go"

    # Should see the content
    assert_text "ProtectedSecret", wait: 5

    # Visit again - cookie is intentionally deleted after first view for security
    # Each view requires re-entering the passphrase
    visit push_path(@push)

    # Should require passphrase again (security feature)
    assert_current_path passphrase_push_path(@push), wait: 5
    assert_selector "input[name='passphrase']", wait: 5
  end

  test "passphrase form validation" do
    visit passphrase_push_path(@push)

    # Try to submit without passphrase
    click_button "Go"

    # Should show validation error or stay on page
    sleep 1
    assert(page.current_path.include?("passphrase") || page.has_text?(/required/i, wait: 5))
  end

  test "passphrase cookie is single-use for security" do
    visit push_path(@push)

    # Enter correct passphrase
    fill_in "passphrase", with: "correctpass"
    click_button "Go"

    assert_text "ProtectedSecret", wait: 5

    # Cookie is deleted immediately after first view for security
    # Visit again - should require passphrase again (even within 3-minute window)
    visit push_path(@push)

    # Should be back on passphrase page (cookie was deleted after first view)
    assert_current_path passphrase_push_path(@push), wait: 5
  end

  test "multiple incorrect passphrase attempts" do
    visit push_path(@push)

    # First incorrect attempt
    fill_in "passphrase", with: "wrong1"
    click_button "Go"

    # Wait for error message to appear and page to stabilize
    assert_selector ".alert, .error, [role='alert']", text: /incorrect/i, wait: 5

    # Second incorrect attempt
    fill_in "passphrase", with: "wrong2"
    click_button "Go"

    # Wait for error message again
    assert_selector ".alert, .error, [role='alert']", text: /incorrect/i, wait: 5

    # Correct passphrase should still work
    fill_in "passphrase", with: "correctpass"
    click_button "Go"
    assert_text "ProtectedSecret", wait: 5
  end

  test "passphrase page shows correct instructions" do
    visit passphrase_push_path(@push)

    # Should show instructions about passphrase
    assert_selector "input[name='passphrase']", wait: 5
    assert_selector "button", text: /go/i, wait: 5
  end

  test "retrieval step with passphrase" do
    @push.update(retrieval_step: true)

    # When retrieval_step is enabled, the URL points to preliminary page
    # Visit the preliminary page directly (this is what the generated URL would be)
    visit preliminary_push_path(@push)

    # Should be on preliminary page
    assert_current_path preliminary_push_path(@push), wait: 5
    click_link "Click Here to Proceed"

    # Then should go to passphrase page (not directly to push)
    assert_current_path passphrase_push_path(@push), wait: 5

    # Enter passphrase
    fill_in "passphrase", with: "correctpass"
    click_button "Go"

    # Finally should see content
    assert_text "ProtectedSecret", wait: 5
  end
end
