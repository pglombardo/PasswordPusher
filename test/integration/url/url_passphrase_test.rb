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

    # Provide the value passphrase
    post forms.first.attributes["action"].value, params: { passphrase: 'asdf' }
    assert_response :redirect
    follow_redirect!
    assert_response :success

    # We should be on the url#show page now
    p_tags = assert_select 'p'
    assert p_tags[0].text == "Please obtain and securely store this content in a secure manner, such as in a url manager."
    assert p_tags[1].text == 'Your url is blurred out.  Click below to reveal it.'
    assert p_tags[2].text.include?('This secret link and all content will be deleted')
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

    # Provide the value passphrase
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
end
