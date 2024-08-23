# frozen_string_literal: true

require "test_helper"

class FilePushReqLocaleTest < ActionDispatch::IntegrationTest
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

  def test_requested_locale
    get new_file_push_path
    assert_response :success

    post file_pushes_path, params: {
      file_push: {
        payload: "Message",
        passphrase: "asdf",
        retrieval_step: true,
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

    # Retrieve the push with a locale
    push_with_locale = request.url.sub("/preview", "") + "/r?locale=es"
    get push_with_locale
    assert_response :success
    assert response.body.include?("<html lang=\"es\">\n")

    links = assert_select("a")
    assert_equal 1, links.count

    push_with_locale = links.first.attributes["href"].value
    get push_with_locale

    # Redirected to the passphrase page
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert response.body.include?("<html lang=\"es\">\n")

    # We should be on the passphrase page now

    # Validate passphrase form
    forms = css_select "form"
    assert_select "form input", 1

    # Provide the value passphrase
    post forms.first.attributes["action"].value, params: {passphrase: "asdf"}
    assert_response :redirect
    follow_redirect!

    # We should be on the password#show page now
    assert_response :success
    assert response.body.include?("<html lang=\"es\">\n")
  end

  def test_requested_locale_without_passphrase
    get new_file_push_path
    assert_response :success

    post file_pushes_path, params: {
      file_push: {
        payload: "Message",
        retrieval_step: true,
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

    # Retrieve the push with a locale
    push_with_locale = request.url.sub("/preview", "") + "/r?locale=es"
    get push_with_locale
    assert_response :success
    assert response.body.include?("<html lang=\"es\">\n")

    links = assert_select("a")
    assert_equal 1, links.count

    push_with_locale = links.first.attributes["href"].value
    get push_with_locale

    # We should be on the password#show page now
    assert_response :success
    assert response.body.include?("<html lang=\"es\">\n")
  end
end
