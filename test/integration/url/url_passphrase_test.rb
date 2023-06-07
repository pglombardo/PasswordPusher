require 'test_helper'

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
    get new_url_path
    assert_response :success

    post urls_path, params: { url: { payload: 'https://pwpush.com', passphrase: 'asdf' } }
    assert_response :redirect

    # Preview page
    follow_redirect!
    assert_response :success
    assert_select 'h2', 'Your push has been created.'

    # Attempt to retrieve the url without the passphrase
    get request.url.sub('/preview', '')
    assert_response :redirect

    # We should get redirected to the passphrase page
    follow_redirect!
    assert_response :success

    # We should be on the passphrase page now

    # Validate passphrase form
    forms = css_select 'form'
    assert_select "form input", 1
    input = css_select 'input#passphrase.form-control'
    assert_equal input.first.attributes["placeholder"].value, "Enter the secret passphrase provided with this URL"

    # Provide a valid passphrase
    post forms.first.attributes["action"].value, params: { passphrase: 'asdf' }
    assert_response :redirect
    follow_redirect!

    assert_response :see_other
    assert_equal "https://pwpush.com", response.headers["Location"]
  end

  def test_url_bad_passphrase
    get new_url_path
    assert_response :success

    post urls_path, params: { url: { payload: 'https://pwpush.com', passphrase: 'asdf' } }
    assert_response :redirect

    # Preview page
    follow_redirect!
    assert_response :success
    assert_select 'h2', 'Your push has been created.'

    # Attempt to retrieve the url without the passphrase
    get request.url.sub('/preview', '')
    assert_response :redirect

    # We should get redirected to the passphrase page
    follow_redirect!
    assert_response :success

    # We should be on the passphrase page now

    # Validate passphrase form
    forms = css_select 'form'
    assert_select "form input", 1
    input = css_select 'input#passphrase.form-control'
    assert_equal input.first.attributes["placeholder"].value, "Enter the secret passphrase provided with this URL"

    # Provide a bad passphrase
    post forms.first.attributes["action"].value, params: { passphrase: 'bad-passphrase' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    # We should be back on the passphrase page now with an error message
    divs = css_select 'div.alert-warning'
    assert divs.first.content.include?('That passphrase is incorrect')

    forms = css_select 'form'
    assert_select "form input", 1
    input = css_select 'input#passphrase.form-control'
    assert_equal input.first.attributes["placeholder"].value, "Enter the secret passphrase provided with this URL"
  end

  def test_anonymous_can_access_url_passphrase
    get new_url_path
    assert_response :success

    post urls_path, params: { url: { payload: 'https://pwpush.com', passphrase: 'asdf' } }
    assert_response :redirect

    # Preview page
    follow_redirect!
    assert_response :success
    assert_select 'h2', 'Your push has been created.'

    @push_url = request.url.sub('/preview', '')
    sign_out :user

    # As an anonymous user, attempt to retrieve the url without the passphrase
    get @push_url
    assert_response :redirect

    # We should get redirected to the passphrase page
    follow_redirect!
    assert_response :success

    # We should be on the passphrase page now

    # Validate passphrase form
    forms = css_select 'form'
    assert_select "form input", 1
    input = css_select 'input#passphrase.form-control'
    assert_equal input.first.attributes["placeholder"].value, "Enter the secret passphrase provided with this URL"

    # Provide a valid passphrase
    post forms.first.attributes["action"].value, params: { passphrase: 'asdf' }
    assert_response :redirect
    follow_redirect!

    assert_response :see_other
    assert_equal "https://pwpush.com", response.headers["Location"]
  end

end
