# frozen_string_literal: true

require "test_helper"

class UrlPassphraseTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_url_pushes = true
    Rails.application.reload_routes!

    @luca = users(:luca)
    @luca.confirm
    sign_in @luca
  end

  teardown do
    sign_out @luca
  end

  def test_url_passphrase
    get new_push_path(tab: "url")
    assert_response :success

    post pushes_path, params: {push: {kind: "url", payload: "https://pwpush.com", passphrase: "asdf"}}
    assert_response :redirect

    # Preview page
    follow_redirect!
    assert_response :success
    assert_select "h2", "Your push has been created."

    # Attempt to retrieve the url without the passphrase
    get request.url.sub("/preview", "")
    assert_response :redirect

    # We should get redirected to the passphrase page
    follow_redirect!
    assert_response :success

    # We should be on the passphrase page now

    # Validate passphrase form
    forms = css_select "form"
    assert_select "form input", 1
    input = css_select "input#passphrase.form-control"
    assert_equal input.first.attributes["placeholder"].value, "Enter the secret passphrase provided with this URL"

    # Provide a valid passphrase
    post forms.first.attributes["action"].value, params: {passphrase: "asdf"}
    assert_response :redirect
    follow_redirect!

    assert_response :see_other
  end

  def test_url_bad_passphrase
    get new_push_path(tab: "url")
    assert_response :success

    post pushes_path, params: {push: {kind: "url", payload: "https://pwpush.com", passphrase: "asdf"}}
    assert_response :redirect

    # Preview page
    follow_redirect!
    assert_response :success
    assert_select "h2", "Your push has been created."

    # Attempt to retrieve the url without the passphrase
    get request.url.sub("/preview", "")
    assert_response :redirect

    # We should get redirected to the passphrase page
    follow_redirect!
    assert_response :success

    # We should be on the passphrase page now

    # Validate passphrase form
    forms = css_select "form"
    assert_select "form input", 1
    input = css_select "input#passphrase.form-control"
    failed_passphrase_log_count = AuditLog.where(kind: :failed_passphrase).count
    assert_equal input.first.attributes["placeholder"].value, "Enter the secret passphrase provided with this URL"

    # Provide a bad passphrase
    post forms.first.attributes["action"].value, params: {passphrase: "bad-passphrase"}
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_equal failed_passphrase_log_count + 1, AuditLog.where(kind: :failed_passphrase).count

    # We should be back on the passphrase page now with an error message
    divs = css_select "div.alert-warning"
    assert divs.first.content.include?("That passphrase is incorrect")

    assert_select "form input", 1
    input = css_select "input#passphrase.form-control"
    assert_equal input.first.attributes["placeholder"].value, "Enter the secret passphrase provided with this URL"
  end

  def test_anonymous_can_access_url_passphrase
    get new_push_path(tab: "url")
    assert_response :success

    post pushes_path, params: {push: {kind: "url", payload: "https://pwpush.com", passphrase: "asdf"}}
    assert_response :redirect

    # Preview page
    follow_redirect!
    assert_response :success
    assert_select "h2", "Your push has been created."

    @push_url = request.url.sub("/preview", "")
    sign_out :user

    # As an anonymous user, attempt to retrieve the url without the passphrase
    get @push_url
    assert_response :redirect

    # We should get redirected to the passphrase page
    follow_redirect!
    assert_response :success

    # We should be on the passphrase page now

    # Validate passphrase form
    forms = css_select "form"
    assert_select "form input", 1
    input = css_select "input#passphrase.form-control"
    assert_equal input.first.attributes["placeholder"].value, "Enter the secret passphrase provided with this URL"

    # Provide a valid passphrase
    post forms.first.attributes["action"].value, params: {passphrase: "asdf"}
    assert_response :redirect
    follow_redirect!

    assert_response :see_other
  end

  def test_url_passphrase_view_tracking
    get new_push_path(tab: "url")
    assert_response :success

    post pushes_path, params: {push: {kind: "url", payload: "https://pwpush.com", passphrase: "asdf"}}
    assert_response :redirect

    # Preview page
    follow_redirect!
    assert_response :success
    assert_select "h2", "Your push has been created."

    push = Push.where(kind: "url").last
    view_count = push.views_remaining

    # Attempt to retrieve the url without the passphrase
    get request.url.sub("/preview", "")
    assert_response :redirect

    # We should get redirected to the passphrase page
    follow_redirect!
    assert_response :success

    # We should be on the passphrase page now

    # Validate passphrase form
    forms = css_select "form"
    assert_select "form input", 1
    input = css_select "input#passphrase.form-control"
    assert_equal input.first.attributes["placeholder"].value, "Enter the secret passphrase provided with this URL"

    # Provide a valid passphrase
    post forms.first.attributes["action"].value, params: {passphrase: "asdf"}
    assert_response :redirect
    follow_redirect!

    assert_response :see_other

    assert push.views_remaining == view_count - 1
  end

  def test_url_passphrase_view_expiration
    get new_push_path(tab: "url")
    assert_response :success

    post pushes_path, params: {push: {kind: "url", payload: "https://pwpush.com", passphrase: "asdf", expire_after_views: 1}}
    assert_response :redirect

    # Preview page
    follow_redirect!
    assert_response :success
    assert_select "h2", "Your push has been created."

    push = Push.where(kind: "url").last
    view_count = push.views_remaining
    secret_url = request.url.sub("/preview", "")

    # Attempt to retrieve the secret url
    get secret_url
    assert_response :redirect

    # We should get redirected to the passphrase page
    follow_redirect!
    assert_response :success

    # We should be on the passphrase page now

    # Validate passphrase form
    forms = css_select "form"
    assert_select "form input", 1
    input = css_select "input#passphrase.form-control"
    assert_equal input.first.attributes["placeholder"].value, "Enter the secret passphrase provided with this URL"

    # Provide an incorrect passphrase
    post forms.first.attributes["action"].value, params: {passphrase: "incorrect"}
    assert_response :redirect
    follow_redirect!
    assert response.body.include?("That passphrase is incorrect.")

    # Provide a valid passphrase
    post forms.first.attributes["action"].value, params: {passphrase: "asdf"}
    assert_response :redirect
    follow_redirect!
    assert_response :see_other

    assert push.views_remaining == view_count - 1

    # Attempt to retrieve the secret url again
    # This time, the push should be expired
    get secret_url
    assert_response :success
    assert response.body.include?("We apologize but this secret link has expired.")
  end
end
