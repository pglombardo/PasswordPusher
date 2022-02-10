require 'test_helper'

class PasswordCreationTest < ActionDispatch::IntegrationTest
  def test_textarea_has_safeties
    get '/'
    assert_response :success

    # Validate some elements
    text_area = css_select 'textarea#password_payload.form-control'

    assert text_area.attribute('spellcheck')
    assert text_area.attribute('spellcheck').value == "false"

    assert text_area.attribute('autocomplete')
    assert text_area.attribute('autocomplete').value == "off"

    assert text_area.attribute('autofocus')
    assert text_area.attribute('autofocus').value == "autofocus"

    assert text_area.attribute('required')
    assert text_area.attribute('required').value == "required"
  end

  def test_password_creation
    get '/'
    assert_response :success

    post '/p', params: { password: { payload: 'testpw' } }
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
    assert p_tags[0].text == "Please obtain and securely store this content in a secure manner, such as in a password manager."
    assert p_tags[1].text == 'Your password is blurred out.  Click below to reveal it.'
    assert p_tags[2].text.include?('This secret link and all content will be deleted')

    # Assert that the right password is in the page
    pre = css_select 'pre'
    assert(pre)
    assert(pre.first.content.include?('testpw'))
  end

  def test_ascii_8bit_password_creation
    get '/'
    assert_response :success

    post '/p', params: { password: { payload: 'æ ¼ ö ç ý' } }
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
    assert p_tags[0].text == "Please obtain and securely store this content in a secure manner, such as in a password manager."
    assert p_tags[1].text == 'Your password is blurred out.  Click below to reveal it.'
    assert p_tags[2].text.include?('This secret link and all content will be deleted')

    # Assert that the right password is in the page
    pre = css_select 'pre'
    assert(pre)
    assert(pre.first.content.include?('æ ¼ ö ç ý'))
  end

  def test_password_creation_uncommon_characters
    get '/'
    assert_response :success

    post '/p', params: { password: { payload: '£' } }
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
    assert p_tags[0].text == "Please obtain and securely store this content in a secure manner, such as in a password manager."
    assert p_tags[1].text == 'Your password is blurred out.  Click below to reveal it.'
    assert p_tags[2].text.include?('This secret link and all content will be deleted')

    # Assert that the right password is in the page
    pre = css_select 'pre'
    assert(pre)
    assert(pre.first.content.include?('£'))
  end

  def test_deletable_by_viewer_enabled_or_not
    get '/'
    assert_response :success

    # DELETABLE_PASSWORDS_ENABLED enables or disables the ability for users
    # to delete passwords when viewing

    deletable_checkbox = css_select '#password_deletable_by_viewer'
    assert(deletable_checkbox)

    found = Settings.enable_deletable_pushes
    deletable_checkbox.each do |item|
      if item.content.include?('Allow viewers to optionally delete password before expiration')
        found = true
      end
    end
    assert found

    # Assert default value on form: DELETABLE_PASSWORDS_DEFAULT
    deletable_checkbox = css_select 'input#password_deletable_by_viewer'
    assert(deletable_checkbox.length == 1)

    # DELETABLE_PASSWORDS_DEFAULT determines initial check state
    if Settings.deletable_pushes_default == true
      assert(deletable_checkbox.first.attributes['checked'].value == 'checked')
    else
      assert(deletable_checkbox.first.attributes['checked'].nil?)
    end
  end

  def test_deletable_by_viewer_honored_when_true
    get '/'
    assert_response :success

    post '/p', params: { password: { payload: 'testpw', deletable_by_viewer: 'on' } }
    assert_response :redirect

    follow_redirect!
    assert_response :success

    # Password page
    get request.url.sub('/preview', '')
    assert_response :success

    # Validate some elements
    p_tags = assert_select 'p'
    assert p_tags[0].text == "Please obtain and securely store this content in a secure manner, such as in a password manager."
    assert p_tags[1].text == 'Your password is blurred out.  Click below to reveal it.'
    assert p_tags[2].text.include?('This secret link and all content will be deleted')

    delete_link = css_select 'button.btn-danger'
    assert(delete_link.length == 1)
    assert(delete_link.children.last.text.include?('Delete This Secret Link Now'))
  end

  def test_deletable_by_viewer_falls_back_to_default
    get '/'
    assert_response :success

    post '/p', params: { password: { payload: 'testpw' } }
    assert_response :redirect

    follow_redirect!
    assert_response :success

    # Password page
    get request.url.sub('/preview', '')
    assert_response :success

    # Validate some elements
    p_tags = assert_select 'p'
    assert p_tags[0].text == "Please obtain and securely store this content in a secure manner, such as in a password manager."
    assert p_tags[1].text == 'Your password is blurred out.  Click below to reveal it.'
    assert p_tags[2].text.include?('This secret link and all content will be deleted')

    delete_button = css_select 'button.btn-danger'

    # HTML Form Checkboxes: when NOT checked the form attribute isn't submitted
    # at all so we set false - NOT deletable by viewers
    assert(delete_button.empty?)
  end
end
