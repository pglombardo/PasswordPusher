# frozen_string_literal: true

require "test_helper"

class PasswordDeliveryFlashTest < ActionDispatch::IntegrationTest
  INCORRECT_PASSPHRASE_FLASH = "That passphrase is incorrect"

  def setup
    @push = pushes(:test_push)
    @push.update!(passphrase: "asdf")
  end

  def test_show_does_not_display_flash_from_previous_request
    post access_push_path(@push), params: {passphrase: "wrong"}
    assert_redirected_to passphrase_push_path(@push)
    follow_redirect!
    assert_includes response.body, INCORRECT_PASSPHRASE_FLASH

    get push_path(@push), params: {passphrase: "asdf"}
    assert_response :success
    assert_not_includes response.body, INCORRECT_PASSPHRASE_FLASH
  end

  def test_preliminary_does_not_display_flash_from_previous_request
    post access_push_path(@push), params: {passphrase: "wrong"}
    assert_redirected_to passphrase_push_path(@push)

    get preliminary_push_path(@push), params: {passphrase: "asdf"}
    assert_response :success
    assert_not_includes response.body, INCORRECT_PASSPHRASE_FLASH
  end

  def test_show_expired_does_not_display_flash_from_previous_request
    post access_push_path(@push), params: {passphrase: "wrong"}
    assert_redirected_to passphrase_push_path(@push)

    @push.update_columns(expired: true, payload_ciphertext: nil)
    get push_path(@push), params: {passphrase: "asdf"}
    assert_response :success
    assert_not_includes response.body, INCORRECT_PASSPHRASE_FLASH
  end
end
