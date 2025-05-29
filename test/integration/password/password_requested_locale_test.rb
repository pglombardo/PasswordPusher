# frozen_string_literal: true

require "test_helper"

class PasswordRequestedLocaleTest < ActionDispatch::IntegrationTest
  def test_requested_locale
    get new_push_path(tab: "text")
    assert_response :success

    post pushes_path, params: {push: {kind: "text", payload: "testpw", passphrase: "asdf", retrieval_step: true}}
    assert_response :redirect

    # Preview page
    follow_redirect!
    assert_response :success
    assert_select "h2", "Your push has been created."

    # Retrieve the push with a locale
    push_with_locale = request.url.sub("/preview", "") + "/r?locale=es"
    get push_with_locale
    assert_response :success
    assert_select "html[lang=es]"

    links = assert_select("a")
    assert_equal 1, links.count

    push_with_locale = links.first.attributes["href"].value
    get push_with_locale

    # Redirected to the passphrase page
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_select "html[lang=es]"

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
    assert_select "html[lang=es]"
  end

  def test_requested_locale_without_passphrase
    get new_push_path(tab: "text")
    assert_response :success

    post pushes_path, params: {push: {kind: "text", payload: "testpw", retrieval_step: true}}
    assert_response :redirect

    # Preview page
    follow_redirect!
    assert_response :success
    assert_select "h2", "Your push has been created."

    # Retrieve the push with a locale
    push_with_locale = request.url.sub("/preview", "") + "/r?locale=es"
    get push_with_locale
    assert_response :success
    assert_select "html[lang=es]"

    links = assert_select("a")
    assert_equal 1, links.count

    push_with_locale = links.first.attributes["href"].value
    get push_with_locale

    # We should be on the password#show page now
    assert_response :success
    assert_select "html[lang=es]"
  end
end
