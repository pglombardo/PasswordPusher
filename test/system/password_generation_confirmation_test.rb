# frozen_string_literal: true

require "application_system_test_case"

class PasswordGenerationConfirmationTest < ApplicationSystemTestCase
  test "shows confirmation modal when existing content is present" do
    visit new_push_path(tab: "text")

    assert_selector "div[data-controller*='pwgen']"
    assert_selector "[data-pwgen-target='payloadInput']"

    fill_in "push_payload", with: "My existing content"
    assert_field "push_payload", with: "My existing content"

    assert_no_text "Are you sure you want to continue?"

    click_on "Generate Password"

    assert_text "Are you sure you want to continue?"

    within '[data-pwgen-target="generateConfirmModal"]' do
      assert_button "Cancel"
      assert_button "Generate Password"
    end

    assert_field "push_payload", with: "My existing content"
  end

  test "shows confirmation modal when existing content is present for QR Code pushes" do
    user = users(:luca)
    login_as(user, scope: :user)

    visit new_push_path(tab: "qr")

    assert_selector "div[data-controller*='pwgen']"
    assert_selector "[data-pwgen-target='payloadInput']"

    fill_in "push_payload", with: "My existing content"

    assert_no_text "Are you sure you want to continue?"

    click_on "Generate Password"

    assert_text "Are you sure you want to continue?"

    logout(:user)
  end

  test "generates password directly when no existing content" do
    visit new_push_path(tab: "text")

    assert_field "push_payload", with: ""

    click_on "Generate Password"
    wait_until_field_has_value("push_payload")

    assert_no_text "Are you sure you want to continue?"

    textarea_content = find_field("push_payload").value
    assert_not_empty textarea_content
  end

  test "cancels password generation from modal" do
    visit new_push_path(tab: "text")

    assert_selector "div[data-controller*='pwgen']"
    assert_selector "[data-pwgen-target='payloadInput']"

    original_content = "My important content"
    fill_in "push_payload", with: original_content

    click_on "Generate Password"

    assert_text "Are you sure you want to continue?"

    within '[data-pwgen-target="generateConfirmModal"]' do
      click_on "Cancel"
    end

    assert_field "push_payload", with: original_content
  end

  test "confirms password generation from modal" do
    visit new_push_path(tab: "text")

    assert_selector "div[data-controller*='pwgen']"
    assert_selector "[data-pwgen-target='payloadInput']"

    original_content = "My important content"
    fill_in "push_payload", with: original_content

    click_on "Generate Password"

    assert_text "Are you sure you want to continue?"

    within '[data-pwgen-target="generateConfirmModal"]' do
      click_on "Generate Password"
    end

    wait_until_field_changes("push_payload", from: original_content)

    new_content = find_field("push_payload").value
    assert_not_empty new_content
    assert_not_equal original_content, new_content
  end

  test "handles subsequent password generation after first generation" do
    visit new_push_path(tab: "text")

    click_on "Generate Password"
    wait_until_field_has_value("push_payload")

    assert_no_text "Are you sure you want to continue?"
    first_generated_password = find_field("push_payload").value
    assert_not_empty first_generated_password

    click_on "Generate Password"
    wait_until_field_changes("push_payload", from: first_generated_password)

    assert_no_text "Are you sure you want to continue?"

    second_generated_password = find_field("push_payload").value
    assert_not_empty second_generated_password
    assert_not_equal first_generated_password, second_generated_password
  end

  test "shows modal when user manually types content after generation" do
    visit new_push_path(tab: "text")

    assert_selector "div[data-controller*='pwgen']"
    assert_selector "[data-pwgen-target='payloadInput']"

    click_on "Generate Password"
    wait_until_field_has_value("push_payload")
    assert_no_text "Are you sure you want to continue?"

    generated_content = find_field("push_payload").value
    assert_not_empty generated_content

    fill_in "push_payload", with: "User manually typed content"

    click_on "Generate Password"

    assert_text "Are you sure you want to continue?"
    assert_text "This will replace the existing content in the text area."
  end
end
