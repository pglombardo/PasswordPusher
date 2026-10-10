# frozen_string_literal: true

require "application_system_test_case"

class PassphraseFieldSystemTest < ApplicationSystemTestCase
  setup do
    Settings.enable_password_pushes = true
    Settings.enable_url_pushes = true
    Settings.enable_file_pushes = true
    Settings.enable_qr_pushes = true
    Rails.application.reload_routes!

    @user = users(:luca)
    login_as(@user, scope: :user)
  end

  teardown do
    Settings.reload!
    Rails.application.reload_routes!
  end

  test "generating a passphrase fills the field and leaves the secret empty" do
    visit new_push_path(tab: "text")

    find("button[aria-label='Generate passphrase']").click
    generated = wait_until_field_has_value("push_passphrase")

    assert_match(/\A(?:[A-Za-z]+-){3}[A-Za-z]+\d{2}\z/, generated)
    assert_equal "", find("textarea#push_payload").value
    assert_selector "button[aria-label='Clear passphrase']"
    assert_selector "button[aria-label='Copy to clipboard']"
  end

  test "clear removes the passphrase and hides copy and clear" do
    visit new_push_path(tab: "text")

    fill_in "push_passphrase", with: "hello world"
    assert_equal "hello world", find_field("push_passphrase").value
    assert_selector "button[aria-label='Clear passphrase']"

    find("button[aria-label='Clear passphrase']").click

    assert_equal "", find_field("push_passphrase").value
    assert_no_selector "button[aria-label='Clear passphrase']"
    assert_no_selector "button[aria-label='Copy to clipboard']"
  end

  test "url form generates a passphrase from saved generator settings" do
    visit new_push_path(tab: "url")
    {
      "pwgen_wordCount" => "3",
      "pwgen_separator" => "_",
      "pwgen_capitalize" => "false",
      "pwgen_number" => "false",
      "pwgen_symbol" => "false"
    }.each do |name, value|
      page.driver.browser.manage.add_cookie(name: name, value: value)
    end
    visit new_push_path(tab: "url")

    find("button[aria-label='Generate passphrase']").click
    generated = wait_until_field_has_value("push_passphrase")

    assert_match(/\A[a-z]+_[a-z]+_[a-z]+\z/, generated)
    assert_equal "", find_field("push_payload").value
  end

  test "copy confirms when the passphrase has a value" do
    visit new_push_path(tab: "files")

    fill_in "push_passphrase", with: "desk-phrase"
    find("button[aria-label='Copy to clipboard']").click

    assert_selector "button[aria-label='Copy to clipboard'] .bi-check-lg"
  end
end
