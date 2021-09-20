require 'test_helper'

class CreateAccountTest < ActionDispatch::IntegrationTest
  def test_account_creation
    skip('Until we support logins for private instances')
    get root_path
    assert_response :success

    # Assert Sign Up Link on Front Page
    sign_up_link = css_select "a.nav-link[href='#{new_user_registration_path}']"
    assert sign_up_link.count == 1

    get new_user_registration_path
    assert_response :success

    sign_up_form = css_select "form.new_user[action='#{user_registration_path}']"
    assert sign_up_form.count == 1

    post user_registration_path, params: { user: { email: 'createaccounttest@test.com',
                                                   password: '123456',
                                                   password_confirmation: '123456' } }
    assert_response :redirect

    # Preview page
    follow_redirect!
    assert_response :success
    assert_select 'h2', 'Your password has been pushed.'

    # Password page
    get request.url.sub('/preview', '')
    assert_response :success

    # Validate some elements
    p_tags = assert_select 'p'
    assert p_tags[0].text == 'Please obtain and securely store this password elsewhere, ' \
                             'ideally in a password manager.'
    assert p_tags[1].text == 'Your password is blurred out.  Click below to reveal it.'
    assert p_tags[2].text.include?('This secret link will be deleted')

    # Assert that the right password is in the page
    pre = css_select 'pre'
    assert(pre)
    assert(pre.first.content.include?('testpw'))
  end
end