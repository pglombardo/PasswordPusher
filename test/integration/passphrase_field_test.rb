# frozen_string_literal: true

require "test_helper"

class PassphraseFieldTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_password_pushes = true
    Settings.enable_url_pushes = true
    Settings.enable_file_pushes = true
    Settings.enable_qr_pushes = true
    Rails.application.reload_routes!

    @luca = users(:luca)
    sign_in @luca
  end

  teardown do
    Settings.reload!
    Rails.application.reload_routes!
  end

  %w[text url files qr].each do |tab|
    test "#{tab} form includes passphrase generator, clear, and copy controls" do
      get new_push_path(tab: tab)
      assert_response :success

      assert_select "input#push_passphrase[data-passphrase-field-target='input']"
      assert_select "button[aria-label='Generate passphrase']"
      assert_select "button[aria-label='Clear passphrase'][hidden]"
      assert_select "button[aria-label='Copy to clipboard'][hidden]"
      assert_select "[data-controller='passphrase-field'][data-passphrase-field-generate-url-value='#{api_v2_generate_path}']"
    end
  end
end
