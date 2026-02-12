# frozen_string_literal: true

require "test_helper"

class FilePushUploadUiTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!
    @user = users(:luca)
    @user.confirm
    sign_in @user
  end

  teardown do
    sign_out :user
  end

  def test_file_form_shows_progress_bar_container
    get new_push_path(tab: "files")
    assert_response :success

    assert_select "ul#progress-bars.list-group"
    assert_select "ul#progress-bars[aria-label='Upload progress']"
    assert_select "div[data-controller='multi-upload']"
    assert_select "ul#selected-files[aria-label='Selected files']"
  end

  def test_file_form_has_upload_templates
    get new_push_path(tab: "files")
    assert_response :success

    assert_select "template#tus-upload-row-template"
    assert_select "template#direct-upload-row-template"
    assert_select "template#selected-file-row-template"
  end

  def test_file_form_when_tus_enabled_shows_tus_ui
    Settings.files.use_tus_uploads = true
    get new_push_path(tab: "files")
    assert_response :success

    assert_select "div[data-controller='multi-upload'][data-multi-upload-tus-enabled-value='true']"
    assert response.body.include?("You can upload up to")
    # Footer when TUS is on does not include "Max ... per file" (only when TUS disabled)
    footer = css_select "#file-count-footer"
    assert footer.any?
    assert_not footer.first.text.include?("per file"), "TUS enabled: footer should not show max size per file"
  end

  def test_file_form_when_tus_disabled_shows_direct_upload_and_max_size_footer
    Settings.files.use_tus_uploads = false
    get new_push_path(tab: "files")
    assert_response :success

    assert_select "div[data-controller='multi-upload'][data-multi-upload-tus-enabled-value='false']"
    # Footer shows max size per file when resumable is disabled
    assert response.body.include?("You can upload up to")
    assert response.body.include?("Max "), "TUS disabled should show max size per file in footer"
  end

  def test_file_form_footer_shows_file_count_message
    get new_push_path(tab: "files")
    assert_response :success

    assert_select "#file-count-footer"
    assert response.body.include?("files per push"), "Footer should show upload limit message"
  end
end
