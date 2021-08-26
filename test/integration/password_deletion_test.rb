require 'test_helper'

class PasswordCreationTest < ActionDispatch::IntegrationTest
  def test_password_deletion
    assert DELETABLE_PASSWORDS_ENABLED == true

    get '/'
    assert_response :success

    # create
    post '/p', params: { password: { payload: 'testpw', deletable_by_viewer: 'on' } }
    assert_response :redirect

    # preview
    follow_redirect!
    assert_response :success
    assert_select 'h2', 'Your password has been pushed.'

    # view the password
    get request.url.sub('/preview', '')
    assert_response :success

    # Assert that the right password is in the page
    pre = css_select 'pre'
    assert(pre)
    assert(pre.first.content.include?('testpw'))

    # Delete the passworda
    delete request.url
    assert_response :redirect

    # Get redirected to the password that is now expired
    follow_redirect!
    assert_response :success
    assert_select 'p', 'We apologize but this secret link has expired.'
  end
end
