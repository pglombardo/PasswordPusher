# frozen_string_literal: true

require "test_helper"

class FilePushUploadUiTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include TusUploadTestSettings

  setup do
    store_tus_related_settings
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!
    @user = users(:luca)
    @user.confirm
    sign_in @user
  end

  teardown do
    sign_out :user
    restore_tus_related_settings
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
    get new_push_path(tab: "files")
    assert_response :success

    assert_select "div[data-controller='multi-upload'][data-multi-upload-tus-enabled-value='true']"
    assert response.body.include?("You can upload up to")
    # Footer shows max size per file (single limit from max_tus_upload_size)
    footer = css_select "#file-count-footer"
    assert footer.any?
    assert footer.first.text.include?("per file"), "Footer should show max size per file"
  end

  def test_file_form_when_tus_enabled_file_input_has_no_direct_upload
    get new_push_path(tab: "files")
    assert_response :success

    file_inputs = css_select "input[type=file][name='push[files][]']"
    assert file_inputs.any?, "File input should be present"
    file_inputs.each do |el|
      assert el["data-direct-upload-url"].blank?,
        "With TUS enabled, file input must not have data-direct-upload-url (direct_upload: false)"
    end
  end

  def test_file_form_footer_shows_file_count_message
    get new_push_path(tab: "files")
    assert_response :success

    assert_select "#file-count-footer"
    assert response.body.include?("files per push"), "Footer should show upload limit message"
  end

  def test_file_form_includes_max_direct_upload_size_data_attribute
    get new_push_path(tab: "files")
    assert_response :success

    expected = Settings.files.max_direct_upload_size.to_i
    assert expected.positive?, "max_direct_upload_size should be configured and positive"
    assert_select "div[data-controller='multi-upload'][data-multi-upload-max-direct-size-value='#{expected}']",
                  1,
                  "Form must expose max direct upload size for client when TUS is disabled"
  end

  def test_max_direct_upload_size_is_configured
    assert Settings.files.max_direct_upload_size.present?
    assert Settings.files.max_direct_upload_size.to_i.positive?,
           "max_direct_upload_size should be a positive number (e.g. 104857600 for 100 MB)"
  end

  def test_tus_create_and_patch_then_file_form_loads
    # Minimal TUS flow: create upload, complete with one PATCH
    post uploads_path, headers: {"Upload-Length" => "3"}
    assert_response :created
    location = response.headers["Location"]
    assert location.present?
    upload_id = File.basename(URI.parse(location).path)

    patch upload_path(upload_id),
      params: "abc",
      headers: {"Content-Type" => "application/offset+octet-stream", "Upload-Offset" => "0"}
    assert_response :no_content
    assert response.headers["X-Signed-Id"].present?, "TUS flow should return signed id"

    # Same session: load file form; ties TUS endpoint and file push UI
    get new_push_path(tab: "files")
    assert_response :success
    assert_select "div[data-controller='multi-upload']"
    assert_select "ul#progress-bars"
    assert_select "ul#selected-files"
  end
end
