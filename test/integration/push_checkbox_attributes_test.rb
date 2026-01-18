# frozen_string_literal: true

require "test_helper"

class PushCheckboxAttributesTest < ActionDispatch::IntegrationTest
  def test_text_push_form_has_x_default_attribute_on_checkboxes
    get new_push_path(tab: "text")
    assert_response :success

    # Verify retrieval_step checkbox has x-default attribute
    retrieval_checkbox = css_select "input#push_retrieval_step[x-default]"
    assert_equal 1, retrieval_checkbox.length, "Retrieval step checkbox should have x-default attribute"

    # Verify deletable_by_viewer checkbox has x-default attribute
    deletable_checkbox = css_select "input#push_deletable_by_viewer[x-default]"
    assert_equal 1, deletable_checkbox.length, "Deletable by viewer checkbox should have x-default attribute"
  end

  def test_url_push_form_has_x_default_attribute_on_checkboxes
    Settings.enable_logins = true
    Settings.enable_url_pushes = true

    user = users(:luca)
    sign_in user

    get new_push_path(tab: "url")
    assert_response :success

    # Verify retrieval_step checkbox has x-default attribute
    retrieval_checkbox = css_select "input#push_retrieval_step[x-default]"
    assert_equal 1, retrieval_checkbox.length, "Retrieval step checkbox should have x-default attribute"
  end

  def test_file_push_form_has_x_default_attribute_on_checkboxes
    Settings.enable_logins = true
    Settings.enable_file_pushes = true

    user = users(:luca)
    sign_in user

    get new_push_path(tab: "file")
    assert_response :success

    # Verify retrieval_step checkbox has x-default attribute
    retrieval_checkbox = css_select "input#push_retrieval_step[x-default]"
    assert_equal 1, retrieval_checkbox.length, "Retrieval step checkbox should have x-default attribute"

    # Verify deletable_by_viewer checkbox has x-default attribute
    deletable_checkbox = css_select "input#push_deletable_by_viewer[x-default]"
    assert_equal 1, deletable_checkbox.length, "Deletable by viewer checkbox should have x-default attribute"
  end

  def test_qr_push_form_has_x_default_attribute_on_checkboxes
    Settings.enable_logins = true
    Settings.enable_qr_pushes = true

    user = users(:luca)
    sign_in user

    get new_push_path(tab: "qr")
    assert_response :success

    # Verify retrieval_step checkbox has x-default attribute
    retrieval_checkbox = css_select "input#push_retrieval_step[x-default]"
    assert_equal 1, retrieval_checkbox.length, "Retrieval step checkbox should have x-default attribute"

    # Verify deletable_by_viewer checkbox has x-default attribute
    deletable_checkbox = css_select "input#push_deletable_by_viewer[x-default]"
    assert_equal 1, deletable_checkbox.length, "Deletable by viewer checkbox should have x-default attribute"
  end

  def test_text_push_edit_form_does_not_have_x_default_attribute
    Settings.enable_logins = true

    user = users(:luca)
    sign_in user

    push = Push.create!(kind: "text", payload: "test password", user: user, retrieval_step: true, deletable_by_viewer: true)

    get edit_push_path(push)
    assert_response :success

    # Verify retrieval_step checkbox does NOT have x-default attribute
    retrieval_checkbox = css_select "input#push_retrieval_step[x-default]"
    assert_equal 0, retrieval_checkbox.length, "Edit form should NOT have x-default on retrieval step checkbox"

    # Verify deletable_by_viewer checkbox does NOT have x-default attribute
    deletable_checkbox = css_select "input#push_deletable_by_viewer[x-default]"
    assert_equal 0, deletable_checkbox.length, "Edit form should NOT have x-default on deletable by viewer checkbox"

    # Verify checkboxes exist but without x-default
    assert_select "input#push_retrieval_step"
    assert_select "input#push_deletable_by_viewer"
  end

  def test_url_push_edit_form_does_not_have_x_default_attribute
    Settings.enable_logins = true
    Settings.enable_url_pushes = true

    user = users(:luca)
    sign_in user

    push = Push.create!(kind: "url", payload: "https://example.com", user: user, retrieval_step: true)

    get edit_push_path(push)
    assert_response :success

    # Verify retrieval_step checkbox does NOT have x-default attribute
    retrieval_checkbox = css_select "input#push_retrieval_step[x-default]"
    assert_equal 0, retrieval_checkbox.length, "Edit form should NOT have x-default on retrieval step checkbox"

    # Verify checkbox exists but without x-default
    assert_select "input#push_retrieval_step"
  end

  def test_file_push_edit_form_does_not_have_x_default_attribute
    Settings.enable_logins = true
    Settings.enable_file_pushes = true

    user = users(:luca)
    sign_in user

    push = Push.create!(kind: "file", user: user, retrieval_step: true, deletable_by_viewer: true)
    push.files.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test-file.txt")),
      filename: "test-file.txt",
      content_type: "text/plain"
    )

    get edit_push_path(push)
    assert_response :success

    # Verify retrieval_step checkbox does NOT have x-default attribute
    retrieval_checkbox = css_select "input#push_retrieval_step[x-default]"
    assert_equal 0, retrieval_checkbox.length, "Edit form should NOT have x-default on retrieval step checkbox"

    # Verify deletable_by_viewer checkbox does NOT have x-default attribute
    deletable_checkbox = css_select "input#push_deletable_by_viewer[x-default]"
    assert_equal 0, deletable_checkbox.length, "Edit form should NOT have x-default on deletable by viewer checkbox"

    # Verify checkboxes exist but without x-default
    assert_select "input#push_retrieval_step"
    assert_select "input#push_deletable_by_viewer"
  end

  def test_x_default_attribute_uses_dash_not_underscore
    get new_push_path(tab: "text")
    assert_response :success

    # Verify the attribute is x-default (with dash) not x_default (with underscore)
    retrieval_checkbox = css_select "input#push_retrieval_step"
    assert_equal 1, retrieval_checkbox.length

    # Check that x-default exists
    assert retrieval_checkbox.first.attributes.key?("x-default"), "Should have 'x-default' attribute with dash"

    # Verify it's not using underscore variant
    assert_not retrieval_checkbox.first.attributes.key?("x_default"), "Should NOT have 'x_default' attribute with underscore"
  end
end
