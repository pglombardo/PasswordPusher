# frozen_string_literal: true

require "test_helper"

class FilePushCreationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca
  end

  teardown do
    sign_out :user
  end

  def test_file_passphrase
    get new_file_push_path
    assert_response :success

    post file_pushes_path, params: {
      file_push: {
        payload: "Message",
        passphrase: "asdf",
        files: [
          fixture_file_upload("monkey.png", "image/jpeg")
        ]
      }
    }
    assert_response :redirect

    # Preview page
    follow_redirect!
    assert_response :success
    assert_select "h2", "Your push has been created."

    # Attempt to access the file push page
    get request.url.sub("/preview", "")
    assert_response :redirect

    follow_redirect!
    assert_response :success

    # We should be on the passphrase page now

    # Validate passphrase form
    forms = css_select "form"
    assert_select "form input", 1
    input = css_select "input#passphrase.form-control"
    assert_equal input.first.attributes["placeholder"].value, "Enter the secret passphrase provided with this URL"

    # Provide the value passphrase
    post forms.first.attributes["action"].value, params: {passphrase: "asdf"}
    assert_response :redirect
    follow_redirect!
    assert_response :success

    # We should be on the password#show page now
    p_tags = assert_select "p"
    assert p_tags[0].text == "The following message has been sent to you along with the files below."
    assert p_tags[1].text == "The message is blurred out.  Click below to reveal it."
    assert p_tags[2].text == "Attached Files"
  end

  def test_file_bad_passphrase
    get new_file_push_path
    assert_response :success

    post file_pushes_path, params: {
      file_push: {
        payload: "Message",
        passphrase: "asdf",
        files: [
          fixture_file_upload("monkey.png", "image/jpeg")
        ]
      }
    }
    assert_response :redirect

    # Preview page
    follow_redirect!
    assert_response :success
    assert_select "h2", "Your push has been created."

    # Attempt to access the file push page
    get request.url.sub("/preview", "")
    assert_response :redirect

    follow_redirect!
    assert_response :success

    # We should be on the passphrase page now

    # Validate passphrase form
    forms = css_select "form"
    assert_select "form input", 1
    input = css_select "input#passphrase.form-control"
    assert_equal input.first.attributes["placeholder"].value, "Enter the secret passphrase provided with this URL"

    # Provide a bad passphrase
    post forms.first.attributes["action"].value, params: {passphrase: "bad-passphrase"}
    assert_response :redirect
    follow_redirect!
    assert_response :success

    # We should be back on the passphrase page now with an error message
    divs = css_select "div.alert-warning"
    assert divs.first.content.include?("That passphrase is incorrect")

    css_select "form"
    assert_select "form input", 1
    input = css_select "input#passphrase.form-control"
    assert_equal input.first.attributes["placeholder"].value, "Enter the secret passphrase provided with this URL"
  end

  def test_anonymous_can_access_file_push_passphrase
    get new_file_push_path
    assert_response :success

    post file_pushes_path, params: {
      file_push: {
        payload: "Message",
        passphrase: "asdf",
        files: [
          fixture_file_upload("monkey.png", "image/jpeg")
        ]
      }
    }
    assert_response :redirect

    # Preview page
    follow_redirect!
    assert_response :success
    assert_select "h2", "Your push has been created."

    # Attempt to access the file push page
    @push_url = request.url.sub("/preview", "")

    sign_out :user

    # As an anonymous user, attempt to retrieve the url without the passphrase
    get @push_url
    assert_response :redirect

    follow_redirect!
    assert_response :success

    # We should be on the passphrase page now

    # Validate passphrase form
    forms = css_select "form"
    assert_select "form input", 1
    input = css_select "input#passphrase.form-control"
    assert_equal input.first.attributes["placeholder"].value, "Enter the secret passphrase provided with this URL"

    # Provide the value passphrase
    post forms.first.attributes["action"].value, params: {passphrase: "asdf"}
    assert_response :redirect
    follow_redirect!
    assert_response :success

    # We should be on the password#show page now
    p_tags = assert_select "p"
    assert p_tags[0].text == "The following message has been sent to you along with the files below."
    assert p_tags[1].text == "The message is blurred out.  Click below to reveal it."
    assert p_tags[2].text == "Attached Files"
  end
end
