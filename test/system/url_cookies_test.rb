# frozen_string_literal: true

require "application_system_test_case"

class UrlCookiesTest < ApplicationSystemTestCase
  setup do
    Settings.enable_logins = true
    Settings.enable_url_pushes = true
    Rails.application.reload_routes!
    @user = users(:luca)
    @user.confirm
    login_as(@user, scope: :user)
  end

  teardown do
    logout(:user)
  end

  test "url form has correct stimulus targets and values" do
    visit new_push_path(tab: "url")
    assert_selector "h5", text: "URL Redirection"

    # Check that the cookie save link exists
    assert_selector "#cookie-save a"
    assert_text "Save the above settings as the page default."

    # Verify the container has the correct data attributes
    assert_selector "div.container[data-controller='knobs form']"

    # Check knobs attributes using JavaScript
    container_data = evaluate_script("document.querySelector('div.container[data-controller=\"knobs form\"]').dataset")

    # Check tab name and language values
    assert_equal "url", container_data["knobsTabNameValue"]
    assert_equal "Save", container_data["knobsLangSaveValue"]
    assert_equal "Saved!", container_data["knobsLangSavedValue"]

    # Check form elements have correct knobs targets
    assert_equal "retrievalStepCheckbox", find("#push_retrieval_step")["data-knobs-target"]
  end

  test "saving settings persists when revisiting url page" do
    visit new_push_path(tab: "url")

    # Get the default values for comparison
    default_days = evaluate_script("document.querySelector('#push_expire_after_days').value")
    default_views = evaluate_script("document.querySelector('#push_expire_after_views').value")
    default_retrieval_step = find("#push_retrieval_step").checked?

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

    # Toggle retrieval step checkbox to opposite of default value
    if default_retrieval_step
      uncheck "push_retrieval_step"
    else
      check "push_retrieval_step"
    end

    # Save the settings
    find("#cookie-save a").click

    # Verify the save confirmation appears
    assert_text "Saved!", wait: 5

    # Navigate away and then revisit the page
    visit root_path
    visit new_push_path(tab: "url")

    # Verify the saved values are restored
    assert_equal custom_days, evaluate_script("document.querySelector('#push_expire_after_days').value")
    assert_equal custom_views, evaluate_script("document.querySelector('#push_expire_after_views').value")
    assert_equal !default_retrieval_step, find("#push_retrieval_step").checked?
  end
end
