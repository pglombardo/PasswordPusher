# frozen_string_literal: true

require "application_system_test_case"

class PushCookiesTest < ApplicationSystemTestCase
  setup do
    Settings.enable_logins = true
    Settings.enable_password_pushes = true
    Rails.application.reload_routes!
    @user = users(:luca)
    @user.confirm
    login_as(@user, scope: :user)
  end

  teardown do
    logout(:user)
  end

  test "password form has correct stimulus targets and values" do
    visit new_push_path(tab: "text")

    # Check that the cookie save link exists
    assert_selector "#cookie-save a"
    assert_text "Save the above settings as the page default."

    # Verify the container has the correct data attributes
    assert_selector "div.container[data-controller='knobs pwgen passwords form']"

    # Check knobs attributes using JavaScript
    container_data = evaluate_script("document.querySelector('div.container[data-controller=\"knobs pwgen passwords form\"]').dataset")

    # Check tab name and language values
    assert_equal "password", container_data["knobsTabNameValue"]
    assert_equal "Save", container_data["knobsLangSaveValue"]
    assert_equal "Saved!", container_data["knobsLangSavedValue"]

    # Check form elements have correct knobs targets
    assert_equal "retrievalStepCheckbox", find("#push_retrieval_step")["data-knobs-target"]
    assert_equal "deletableByViewerCheckbox", find("#push_deletable_by_viewer")["data-knobs-target"]
  end

  test "saving settings persists when revisiting password page" do
    visit new_push_path(tab: "text")

    # Get the default values for comparison
    default_days = evaluate_script("document.querySelector('#push_expire_after_days').value")
    default_views = evaluate_script("document.querySelector('#push_expire_after_views').value")
    default_retrieval_step = find("#push_retrieval_step").checked?
    default_deletable_by_viewer = find("#push_deletable_by_viewer").checked?

    # Set custom values (different from defaults)
    custom_days = (default_days.to_i + 3).to_s
    custom_views = (default_views.to_i + 2).to_s

    # Change form values
    execute_script("
      document.querySelector('#push_expire_after_days').value = #{custom_days};
      document.querySelector('#push_expire_after_days').dispatchEvent(new Event('input'));
      document.querySelector('#push_expire_after_views').value = #{custom_views};
      document.querySelector('#push_expire_after_views').dispatchEvent(new Event('input'));
    ")

    # Toggle checkboxes to opposite of default values
    if default_retrieval_step
      uncheck "push_retrieval_step"
    else
      check "push_retrieval_step"
    end

    if default_deletable_by_viewer
      uncheck "push_deletable_by_viewer"
    else
      check "push_deletable_by_viewer"
    end

    # Save the settings
    find("#cookie-save a").click

    # Verify the save confirmation appears
    assert_text "Saved!", wait: 5

    # Navigate away and then revisit the page
    visit root_path
    visit new_push_path(tab: "text")

    # Verify the saved values are restored
    assert_equal custom_days, evaluate_script("document.querySelector('#push_expire_after_days').value")
    assert_equal custom_views, evaluate_script("document.querySelector('#push_expire_after_views').value")
    assert_equal !default_retrieval_step, find("#push_retrieval_step").checked?
    assert_equal !default_deletable_by_viewer, find("#push_deletable_by_viewer").checked?
  end

  test "generate password shows confirmation modal when content exists" do
    visit new_push_path(tab: "text")

    # First, add some content to the payload textarea
    existing_content = "my existing password"
    fill_in "push_payload", with: existing_content

    # Click the generate password button
    find("#generate_password").click

    # Verify that the confirmation modal is shown
    assert_selector "#confirmModal.show", visible: true, wait: 2
    assert_text "This will replace the existing content in the text area."
    assert_text "Are you sure you want to continue?"

    # Click Cancel button in the modal
    find("#confirmModal button", text: "Cancel").click

    # Wait a moment for the modal to process the dismiss action
    sleep(0.5)

    # Verify modal is not visible and content hasn't changed
    assert_selector "#confirmModal:not(.show)", wait: 5
    assert_equal existing_content, find("#push_payload").value

    # Click generate password button again
    find("#generate_password").click

    # Wait for modal to appear
    assert_selector "#confirmModal.show", visible: true, wait: 2

    # Click "Generate Password" button in the modal
    find("#confirmModal button", text: "Generate Password").click

    # Wait a moment for the modal to process the dismiss action and password generation
    sleep(0.5)

    # Verify that the modal is closed and content has been replaced
    assert_selector "#confirmModal:not(.show)", wait: 5
    assert_not_equal existing_content, find("#push_payload").value
    assert find("#push_payload").value.length > 0, "Generated password should not be empty"
  end

  test "generate password works without confirmation when textarea is empty" do
    visit new_push_path(tab: "text")

    # Ensure the payload textarea is empty
    fill_in "push_payload", with: ""

    # Click the generate password button
    find("#generate_password").click

    # Verify that modal is not shown for empty content
    assert_no_selector "#confirmModal.show", wait: 1

    # Verify that a password was generated directly
    assert find("#push_payload").value.length > 0, "Generated password should not be empty"
  end

  test "generate password replaces previously generated password without confirmation" do
    visit new_push_path(tab: "text")

    # Ensure the payload textarea is empty initially
    fill_in "push_payload", with: ""

    # Generate a password first time
    find("#generate_password").click

    # Verify a password was generated
    first_password = find("#push_payload").value
    assert first_password.length > 0, "First generated password should not be empty"

    # Click generate password button again (should replace without confirmation)
    find("#generate_password").click

    # Verify that modal is not shown for generated content
    assert_no_selector "#confirmModal.show", wait: 1

    # Verify that the password was replaced with a new one
    second_password = find("#push_payload").value
    assert second_password.length > 0, "Second generated password should not be empty"
    assert_not_equal first_password, second_password, "Second password should be different from first"
  end

  test "generate password shows confirmation after manual edit of generated password" do
    visit new_push_path(tab: "text")

    # Generate a password first
    find("#generate_password").click

    # Verify a password was generated
    generated_password = find("#push_payload").value
    assert generated_password.length > 0, "Generated password should not be empty"

    # Manually edit the generated password (this should reset the generated flag)
    modified_content = generated_password + " manually edited"
    fill_in "push_payload", with: modified_content

    # Click generate password button again (should now show confirmation for manually edited content)
    find("#generate_password").click

    # Verify that the confirmation modal is shown
    assert_selector "#confirmModal.show", visible: true, wait: 2
    assert_text "This will replace the existing content in the text area."

    # Click Cancel to verify the content is preserved
    find("#confirmModal button", text: "Cancel").click

    # Wait for modal to close
    sleep(0.5)

    # Verify modal is not visible and manually edited content is preserved
    assert_not find("#confirmModal")[:class].include?("show")
    assert_equal modified_content, find("#push_payload").value
  end
end
