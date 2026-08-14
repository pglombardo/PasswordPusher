# frozen_string_literal: true

require "application_system_test_case"

class PayloadVisibilityTest < ApplicationSystemTestCase
  setup do
    Settings.enable_password_pushes = true
    Rails.application.reload_routes!

    @user = users(:luca)
    login_as(@user, scope: :user)
  end

  teardown do
    clear_payload_visibility_storage
    Settings.reload!
    Rails.application.reload_routes!
  end

  test "toggle masks and unmasks payload while keeping value" do
    visit_text_form_with_clean_visibility

    payload_input = find("textarea#push_payload", wait: 5)
    toggle = find("button[data-action='payload-visibility#toggle']", wait: 5)

    fill_in "push_payload", with: "MySecretPassword123!"
    assert_equal "MySecretPassword123!", payload_input.value
    assert_not payload_input[:class].to_s.include?("payload-hidden")
    assert_equal "false", toggle["aria-pressed"]

    toggle.click

    assert payload_input[:class].to_s.include?("payload-hidden")
    assert_equal "MySecretPassword123!", payload_input.value
    assert_equal "true", toggle["aria-pressed"]
    assert_equal "Show payload", toggle["aria-label"]

    toggle.click

    assert_not payload_input[:class].to_s.include?("payload-hidden")
    assert_equal "MySecretPassword123!", payload_input.value
    assert_equal "false", toggle["aria-pressed"]
    assert_equal "Hide payload", toggle["aria-label"]
  end

  test "generate password works while payload is masked" do
    visit_text_form_with_clean_visibility

    payload_input = find("textarea#push_payload", wait: 5)
    toggle = find("button[data-action='payload-visibility#toggle']", wait: 5)
    generate_button = find("button[data-action*='pwgen#producePassword']", match: :first, wait: 5)

    toggle.click
    assert payload_input[:class].to_s.include?("payload-hidden")

    generate_button.click
    sleep 0.5

    generated = payload_input.value
    assert generated.present?
    assert payload_input[:class].to_s.include?("payload-hidden")
  end

  test "masked preference persists across page loads" do
    visit_text_form_with_clean_visibility

    toggle = find("button[data-action='payload-visibility#toggle']", wait: 5)
    toggle.click
    assert_equal "true", toggle["aria-pressed"]

    visit new_push_path(tab: "text")

    payload_input = find("textarea#push_payload", wait: 5)
    toggle = find("button[data-action='payload-visibility#toggle']", wait: 5)

    assert payload_input[:class].to_s.include?("payload-hidden")
    assert_equal "true", toggle["aria-pressed"]
    assert_equal "Show payload", toggle["aria-label"]
  end

  private

  def visit_text_form_with_clean_visibility
    visit new_push_path(tab: "text")
    clear_payload_visibility_storage
    visit new_push_path(tab: "text")
  end

  def clear_payload_visibility_storage
    return unless page.current_url.present? && page.current_url.start_with?("http")

    page.execute_script("try { localStorage.removeItem('pwpush_payload_hidden') } catch (e) {}")
  rescue Selenium::WebDriver::Error::WebDriverError,
    Selenium::WebDriver::Error::InvalidSessionIdError,
    Selenium::WebDriver::Error::NoSuchWindowError,
    Selenium::WebDriver::Error::JavascriptError
    # Browser already closed or on a non-http page
  end
end
