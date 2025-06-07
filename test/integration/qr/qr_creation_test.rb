# frozen_string_literal: true

require "test_helper"

class QrCreationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_qr_pushes = true
    Rails.application.reload_routes!

    @luca = users(:luca)
    @luca.confirm
    sign_in @luca
  end

  teardown do
    sign_out @luca
  end

  def test_textarea_has_safeties
    get new_push_path(tab: "qr")
    assert_response :success

    # Validate some elements
    text_area = css_select "textarea#push_payload.form-control"

    assert text_area.attribute("spellcheck")
    assert text_area.attribute("spellcheck").value == "false"

    assert text_area.attribute("autocomplete")
    assert text_area.attribute("autocomplete").value == "off"

    assert text_area.attribute("autofocus")
    assert text_area.attribute("autofocus").value == "autofocus"

    assert text_area.attribute("required")
    assert text_area.attribute("required").value == "required"

    assert text_area.attribute("maxlength")
    assert text_area.attribute("maxlength").value == "1024"
  end

  def test_url_creation
    get new_push_path(tab: "qr")
    assert_response :success

    post pushes_path, params: {push: {kind: "qr", payload: "testqr"}}
    assert_response :redirect

    # Preview page
    follow_redirect!
    assert_response :success
    assert_select "h2", "Your push has been created."

    # Password page
    get request.url.sub("/preview", "")
    assert_response :success

    # Validate some elements
    p_tags = assert_select "p"
    assert p_tags[0].text == "Please obtain and securely store this content in a secure manner, such as in a password manager."
    assert p_tags[1].text.include?("This secret link and all content will be deleted")

    # Assert that the right password is in the page
    svg = css_select "svg"
    assert(svg)
    rect_elements = svg.css("rect")
    assert_equal 222, rect_elements.length
  end
end
