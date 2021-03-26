require 'test_helper'

class PasswordCreationTest < ActionDispatch::IntegrationTest
  def test_password_deletion
    assert DELETABLE_BY_VIEWER_PASSWORDS == true

    get '/'
    assert_response :success

    # create
    post '/p', params: { password: { payload: 'testpw', deletable_by_viewer: 'on' } }
    assert_response :redirect

    # preview
    follow_redirect!
    assert_response :success
    assert_select 'p', 'Your password has been pushed.'

    # view the password
    get request.url.sub('/preview', '')
    assert_response :success

    # Assert that the right password is in the page
    divs = css_select 'div#pass'
    assert(divs)
    assert(divs.first.content.include?('testpw'))

    assert_select 'a', 'Nah. I\'ve got it. Delete this secret link now.'

    # Delete the passworda
    delete request.url
    assert_response :redirect

    # Get redirected to the password that is now expired
    follow_redirect!
    assert_response :success
    assert_select 'p', 'We apologize but this secret link has expired.'
  end
end
