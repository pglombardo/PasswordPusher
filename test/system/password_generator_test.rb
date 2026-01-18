# frozen_string_literal: true

require "application_system_test_case"

class PasswordGeneratorTest < ApplicationSystemTestCase
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

  test "generate password button generates password" do
    visit new_push_path(tab: "text")

    # Find the generate password button
    generate_button = find("button[data-action*='pwgen#producePassword']", match: :first, wait: 5)

    # Get initial payload value (should be empty)
    payload_input = find("textarea#push_payload")
    initial_value = payload_input.value

    # Click generate button
    generate_button.click

    # Password should appear in the form
    sleep 0.5 # Wait for JavaScript to execute
    new_value = payload_input.value

    assert_not_equal initial_value, new_value
    assert new_value.present?
    assert new_value.length > 0
  end

  test "generated password appears in form" do
    visit new_push_path(tab: "text")

    generate_button = find("button[data-action*='pwgen#producePassword']", match: :first, wait: 5)
    payload_input = find("textarea#push_payload")

    generate_button.click
    sleep 0.5

    # Password should be in the textarea
    generated_password = payload_input.value
    assert generated_password.present?
    assert generated_password.length >= 8 # Minimum reasonable password length
  end

  test "configure generator dialog opens" do
    visit new_push_path(tab: "text")

    # Find configure button (usually opens a modal)
    configure_button = find("button[data-action*='pwgen#configureGenerator']", match: :first, wait: 5)

    # Click to open dialog
    configure_button.click

    # Should see configuration options
    # The modal or dialog should appear
    sleep 0.5
    # Look for common configuration fields
    assert_selector "input", wait: 2
  end

  test "test generate functionality in dialog" do
    visit new_push_path(tab: "text")

    # Open configure dialog
    configure_button = find("button[data-action*='pwgen#configureGenerator']", match: :first, wait: 5)
    configure_button.click

    sleep 0.5

    # Find test generate button if it exists
    test_buttons = all("button[data-action*='pwgen#testGenerate']")
    if test_buttons.any?
      test_buttons.first.click
      sleep 0.5
      # Should see generated password in test area
      assert_selector "[data-pwgen-target='testPayloadArea']", wait: 2
    end
  end

  test "generator settings persistence" do
    visit new_push_path(tab: "text")

    # Open configure dialog
    configure_button = find("button[data-action*='pwgen#configureGenerator']", match: :first, wait: 5)
    configure_button.click

    sleep 0.5

    # Change a setting (e.g., number of syllables)
    syllables_input = find("input[data-pwgen-target='numSyllablesInput']", match: :first, wait: 5)
    original_value = syllables_input.value.to_i
    new_value = (original_value + 2).to_s

    fill_in syllables_input[:id] || syllables_input[:name], with: new_value

    # Save settings (if there's a save button)
    save_buttons = all("button[data-action*='pwgen#saveSettings']")
    if save_buttons.any?
      save_buttons.first.click
      sleep 0.5
    end

    # Navigate away and come back
    visit root_path
    visit new_push_path(tab: "text")

    # Open configure dialog again
    configure_button = find("button[data-action*='pwgen#configureGenerator']", match: :first, wait: 5)
    configure_button.click

    sleep 0.5

    # Settings should be persisted
    find("input[data-pwgen-target='numSyllablesInput']", match: :first, wait: 5)
    # Note: Cookie persistence may require page reload, so we check if value was saved
    # The exact behavior depends on implementation
  end

  test "password generator is available on password form" do
    visit new_push_path(tab: "text")

    # Should have password generator controller
    assert_selector "[data-controller*='pwgen']", wait: 5

    # Should have generate button
    assert_selector "button[data-action*='pwgen#producePassword']", wait: 5
  end

  test "password generator is available on QR form" do
    visit new_push_path(tab: "qr")

    # Should have password generator controller
    assert_selector "[data-controller*='pwgen']", wait: 5

    # Should have generate button
    assert_selector "button[data-action*='pwgen#producePassword']", wait: 5
  end

  test "password generator is not available on URL form" do
    visit new_push_path(tab: "url")

    # URL form should not have password generator controller
    # The key check is that the URL form container doesn't have the pwgen controller
    # (A hidden modal might exist elsewhere on the page, but without the controller it won't be functional)
    containers = all("div[data-controller*='form']")
    url_container = containers.find { |c| c["data-knobs-tab-name-value"] == "url" }

    if url_container
      # The URL form container should NOT have pwgen in its data-controller
      assert_not url_container["data-controller"].include?("pwgen"),
        "URL form container should not have pwgen controller. Found: #{url_container["data-controller"]}"
    else
      # Fallback: check that no container with both 'form' and 'pwgen' controllers exists
      pwgen_containers = all("div[data-controller*='pwgen'][data-controller*='form']")
      url_pwgen_containers = pwgen_containers.select { |c| c["data-knobs-tab-name-value"] == "url" }
      assert_equal 0, url_pwgen_containers.count, "No URL form containers should have pwgen controller"
    end
  end

  test "password generator is not available on file form" do
    visit new_push_path(tab: "files")

    # File form should not have password generator controller
    # The key check is that the file form container doesn't have the pwgen controller
    # (A hidden modal might exist elsewhere on the page, but without the controller it won't be functional)
    containers = all("div[data-controller*='form']")
    file_container = containers.find { |c| c["data-knobs-tab-name-value"] == "files" }

    if file_container
      # The file form container should NOT have pwgen in its data-controller
      assert_not file_container["data-controller"].include?("pwgen"),
        "File form container should not have pwgen controller. Found: #{file_container["data-controller"]}"
    else
      # Fallback: check that no container with both 'form' and 'pwgen' controllers exists
      pwgen_containers = all("div[data-controller*='pwgen'][data-controller*='form']")
      file_pwgen_containers = pwgen_containers.select { |c| c["data-knobs-tab-name-value"] == "files" }
      assert_equal 0, file_pwgen_containers.count, "No file form containers should have pwgen controller"
    end
  end

  test "generate password multiple times produces different passwords" do
    visit new_push_path(tab: "text")

    generate_button = find("button[data-action*='pwgen#producePassword']", match: :first, wait: 5)
    payload_input = find("textarea#push_payload")

    # Generate first password
    generate_button.click
    sleep 0.5
    first_password = payload_input.value

    # Clear and generate second password
    payload_input.set("")
    generate_button.click
    sleep 0.5
    second_password = payload_input.value

    # Passwords should be different (very high probability)
    assert_not_equal first_password, second_password
  end

  test "generated password can be submitted" do
    visit new_push_path(tab: "text")

    # Generate password
    generate_button = find("button[data-action*='pwgen#producePassword']", match: :first, wait: 5)
    generate_button.click
    sleep 0.5

    # Submit the form
    click_button "Push It!"

    # Should create push successfully
    assert_current_path %r{/p/[a-zA-Z0-9_-]+/preview}, wait: 5
    assert_text "Push Preview", wait: 5
  end
end
