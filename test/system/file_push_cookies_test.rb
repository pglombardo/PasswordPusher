# frozen_string_literal: true

require "application_system_test_case"

class FilePushCookiesTest < ApplicationSystemTestCase
  setup do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!
    @user = users(:luca)
    @user.confirm
    login_as(@user, scope: :user)
  end

  teardown do
    logout(:user)
  end

  test "file push form has correct stimulus targets and values" do
    visit new_push_path(tab: "files")
    assert_selector "h5", text: "Add Files..."

    # Check that the cookie save link exists
    assert_selector "#cookie-save a"
    assert_text "Save the above settings as the page default."

    # Verify the container has the correct data attributes
    assert_selector "div.container[data-controller='knobs form']"

    # Check knobs attributes using JavaScript
    container_data = evaluate_script("document.querySelector('div.container[data-controller=\"knobs form\"]').dataset")

    # Check tab name and language values
    assert_equal "file", container_data["knobsTabNameValue"]
    assert_equal "Save", container_data["knobsLangSaveValue"]
    assert_equal "Saved!", container_data["knobsLangSavedValue"]

    # Check form elements have correct knobs targets
    assert_equal "retrievalStepCheckbox", find("#push_retrieval_step")["data-knobs-target"]
    assert_equal "deletableByViewerCheckbox", find("#push_deletable_by_viewer")["data-knobs-target"]
  end

  test "saving settings persists when revisiting file push page" do
    visit new_push_path(tab: "files")

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
    visit new_push_path(tab: "files")

    # Verify the saved values are restored
    assert_equal custom_days, evaluate_script("document.querySelector('#push_expire_after_days').value")
    assert_equal custom_views, evaluate_script("document.querySelector('#push_expire_after_views').value")
    assert_equal !default_retrieval_step, find("#push_retrieval_step").checked?
    assert_equal !default_deletable_by_viewer, find("#push_deletable_by_viewer").checked?
  end
end
