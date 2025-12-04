# frozen_string_literal: true

require "application_system_test_case"

class PasswordGenerationConfirmationTest < ApplicationSystemTestCase
  test "shows confirmation modal when existing content is present" do
    visit new_push_path(tab: "text")

    # Wait for JavaScript to be fully loaded
    assert_selector "div[data-controller*='pwgen']"

    # Verify the pwgen controller is connected by checking for the target
    assert_selector "[data-pwgen-target='payloadInput']"

    # Fill in some existing content in the textarea
    fill_in "push_payload", with: "My existing content"
    assert_field "push_payload", with: "My existing content"

    assert_no_text "Are you sure you want to continue?"

    # Click the Generate Password button
    click_on "Generate Password"

    # Ensure modal is fully visible by forcing it via JavaScript (workaround for timing issues)
    # page.execute_script("document.querySelector('[data-pwgen-target=\"generateConfirmModal\"]').classList.add('show'); document.querySelector('[data-pwgen-target=\"generateConfirmModal\"]').style.display = 'block';")

    # Assert that the confirmation modal is visible
    assert_text "Are you sure you want to continue?"

    # Check that modal has Cancel and Generate Password buttons
    within '[data-pwgen-target="generateConfirmModal"]' do
      assert_button "Cancel"
      assert_button "Generate Password"
    end

    # Verify the original content is still in the textarea
    assert_field "push_payload", with: "My existing content"
  end

  test "shows confirmation modal when existing content is present for QR Code pushes" do
    user = users(:luca)
    user.confirm
    login_as(user, scope: :user)

    visit new_push_path(tab: "qr")

    # Wait for JavaScript to be fully loaded
    assert_selector "div[data-controller*='pwgen']"
    assert_selector "[data-pwgen-target='payloadInput']"

    # Fill in some existing content in the textarea
    fill_in "push_payload", with: "My existing content"

    assert_no_text "Are you sure you want to continue?"

    # Click the Generate Password button
    click_on "Generate Password"

    # Ensure modal is fully visible by forcing it via JavaScript (workaround for timing issues)
    # page.execute_script("document.querySelector('[data-pwgen-target=\"generateConfirmModal\"]').classList.add('show'); document.querySelector('[data-pwgen-target=\"generateConfirmModal\"]').style.display = 'block';")

    # Assert that the confirmation modal is visible
    assert_text "Are you sure you want to continue?"

    logout(:user)
  end

  test "generates password directly when no existing content" do
    visit new_push_path(tab: "text")

    # Ensure textarea is empty
    assert_field "push_payload", with: ""

    # Click the Generate Password button
    click_on "Generate Password"

    # Modal should not appear and password should be generated directly
    assert_no_text "Are you sure you want to continue?"

    # Check that content was generated (should not be empty anymore)
    textarea_content = find_field("push_payload").value
    assert_not_empty textarea_content
  end

  test "cancels password generation from modal" do
    visit new_push_path(tab: "text")

    # Wait for JavaScript to be fully loaded
    assert_selector "div[data-controller*='pwgen']"
    assert_selector "[data-pwgen-target='payloadInput']"

    # Fill in some existing content
    original_content = "My important content"
    fill_in "push_payload", with: original_content

    # Click the Generate Password button to open modal
    click_on "Generate Password"

    # Ensure modal is fully visible by forcing it via JavaScript (workaround for timing issues)
    # page.execute_script("document.querySelector('[data-pwgen-target=\"generateConfirmModal\"]').classList.add('show'); document.querySelector('[data-pwgen-target=\"generateConfirmModal\"]').style.display = 'block';")

    # Verify modal is visible
    assert_text "Are you sure you want to continue?"

    # Click Cancel button
    within '[data-pwgen-target="generateConfirmModal"]' do
      click_on "Cancel"
    end

    # Original content should remain unchanged (main test assertion)
    assert_field "push_payload", with: original_content
  end

  test "confirms password generation from modal" do
    visit new_push_path(tab: "text")

    # Wait for JavaScript to be fully loaded
    assert_selector "div[data-controller*='pwgen']"
    assert_selector "[data-pwgen-target='payloadInput']"

    # Fill in some existing content
    original_content = "My important content"
    fill_in "push_payload", with: original_content

    # Click the Generate Password button to open modal
    click_on "Generate Password"

    # Ensure modal is fully visible by forcing it via JavaScript (workaround for timing issues)
    # page.execute_script("document.querySelector('[data-pwgen-target=\"generateConfirmModal\"]').classList.add('show'); document.querySelector('[data-pwgen-target=\"generateConfirmModal\"]').style.display = 'block';")

    # Verify modal is visible
    assert_text "Are you sure you want to continue?"

    # Click Generate Password button in modal
    within '[data-pwgen-target="generateConfirmModal"]' do
      click_on "Generate Password"
    end

    # Content should be replaced with generated password (main test assertion)
    new_content = find_field("push_payload").value
    assert_not_empty new_content
    assert_not_equal original_content, new_content
  end

  test "handles subsequent password generation after first generation" do
    visit new_push_path(tab: "text")

    # First generation - no existing content
    click_on "Generate Password"

    # Should generate directly without modal
    assert_no_text "Are you sure you want to continue?"
    first_generated_password = find_field("push_payload").value
    assert_not_empty first_generated_password

    # Second generation - should also generate directly since content was generated by controller
    click_on "Generate Password"

    # Should generate directly without modal (content was generated by same controller)
    assert_no_text "Are you sure you want to continue?"

    second_generated_password = find_field("push_payload").value
    assert_not_empty second_generated_password
    assert_not_equal first_generated_password, second_generated_password
  end

  test "shows modal when user manually types content after generation" do
    visit new_push_path(tab: "text")

    # Wait for JavaScript to be fully loaded
    assert_selector "div[data-controller*='pwgen']"
    assert_selector "[data-pwgen-target='payloadInput']"

    # Generate a password first
    click_on "Generate Password"
    assert_no_text "Are you sure you want to continue?"

    generated_content = find_field("push_payload").value
    assert_not_empty generated_content

    # User manually modifies the content (simulating typing)
    fill_in "push_payload", with: "User manually typed content"

    # Now clicking Generate Password should show the modal
    click_on "Generate Password"

    # Ensure modal is fully visible by forcing it via JavaScript (workaround for timing issues)
    # page.execute_script("document.querySelector('[data-pwgen-target=\"generateConfirmModal\"]').classList.add('show'); document.querySelector('[data-pwgen-target=\"generateConfirmModal\"]').style.display = 'block';")

    assert_text "Are you sure you want to continue?"
    assert_text "This will replace the existing content in the text area."
  end
end
