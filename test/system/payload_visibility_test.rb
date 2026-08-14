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
    Settings.reload!
    Rails.application.reload_routes!
  end

  test "toggle masks and unmasks payload while keeping value" do
    visit new_push_path(tab: "text")

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
    visit new_push_path(tab: "text")

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
    visit new_push_path(tab: "text")

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
end
