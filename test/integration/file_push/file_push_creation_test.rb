require 'test_helper'

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

  def test_textarea_has_safeties
    get new_file_push_path
    assert_response :success
    assert response.body.include?('You can upload up to 10 files per push.')

    # Validate some elements
    text_area = css_select 'textarea#file_push_payload.form-control'
    
    assert text_area.attribute('spellcheck')
    assert text_area.attribute('spellcheck').value == "false"

    assert text_area.attribute('autocomplete')
    assert text_area.attribute('autocomplete').value == "off"
    
    file_input = css_select 'input#file_push_files.form-control'
    
    assert file_input.attribute('required')
    assert file_input.attribute('required').value == "required"
  end

  def test_file_push_creation
    get new_file_push_path
    assert_response :success

    post file_pushes_path, params: { 
      file_push: { 
        payload: 'Message',
        files: [ 
          fixture_file_upload('monkey.png', 'image/jpeg')
        ]
      }
    }
    assert_response :redirect

    # Preview page
    follow_redirect!
    assert_response :success
    assert_select 'h2', 'Your push has been created.'

    # File Push page
    get request.url.sub('/preview', '')
    assert_response :success

    # Validate some elements
    p_tags = assert_select 'p'
    assert p_tags[0].text == "The following message has been sent to you along with the files below."
    assert p_tags[1].text == 'The message is blurred out.  Click below to reveal it.'
    assert p_tags[2].text == 'Attached Files'
    assert p_tags[3].text.include?('This secret link and all content will be deleted')

    # Assert that the right password is in the page
    download_link = css_select 'a.list-group-item.list-group-item-action'
    assert(download_link)
    assert(download_link.first.content.include?('monkey.png'))
  end

  def test_ascii_8bit_message_creation
    get new_file_push_path
    assert_response :success

    post file_pushes_path, params: { 
      file_push: { 
        payload: 'æ ¼ ö ç ý',
        files: [ 
          fixture_file_upload('monkey.png', 'image/jpeg')
        ]
      }
    }
    assert_response :redirect

    # Preview page
    follow_redirect!
    assert_response :success
    assert_select 'h2', 'Your push has been created.'

    # File Push page
    get request.url.sub('/preview', '')
    assert_response :success

    # Validate some elements
    p_tags = assert_select 'p'
    assert p_tags[0].text == "The following message has been sent to you along with the files below."
    assert p_tags[1].text == 'The message is blurred out.  Click below to reveal it.'
    assert p_tags[2].text == 'Attached Files'
    assert p_tags[3].text.include?('This secret link and all content will be deleted')
    
    pre = css_select 'pre'
    assert(pre)
    assert(pre.first.content.include?('æ ¼ ö ç ý'))

    # Assert that the right content is in the page
    download_link = css_select 'a.list-group-item.list-group-item-action'
    assert(download_link)
    assert(download_link.first.content.include?('monkey.png'))
  end

  def test_deletable_by_viewer_enabled_or_not
    get new_file_push_path
    assert_response :success

    # DELETABLE_PASSWORDS_ENABLED enables or disables the ability for users
    # to delete file_pushes when viewing

    deletable_checkbox = css_select '#file_push_deletable_by_viewer'
    assert(deletable_checkbox)

    found = Settings.files.enable_deletable_pushes
    deletable_checkbox.each do |item|
      if item.content.include?('Allow users to delete this push once retrieved.')
        found = true
      end
    end
    assert found

    # Assert default value on form: DELETABLE_PASSWORDS_DEFAULT
    deletable_checkbox = css_select 'input#file_push_deletable_by_viewer'
    assert(deletable_checkbox.length == 1)

    # DELETABLE_PASSWORDS_DEFAULT determines initial check state
    if Settings.files.deletable_pushes_default == true
      assert(deletable_checkbox.first.attributes['checked'].value == 'checked')
    else
      assert(deletable_checkbox.first.attributes['checked'].nil?)
    end
  end

  def test_deletable_by_viewer_honored_when_true
    get new_file_push_path
    assert_response :success

    post file_pushes_path, params: { 
      file_push: { 
        payload: 'æ ¼ ö ç ý',
        deletable_by_viewer: true,
        files: [ 
          fixture_file_upload('monkey.png', 'image/jpeg')
        ]
      }
    }
    assert_response :redirect

    follow_redirect!
    assert_response :success

    # File Push page
    get request.url.sub('/preview', '')
    assert_response :success

    delete_link = css_select 'button.btn-danger'
    assert(delete_link.length == 1)
    assert(delete_link.children.last.text.include?('Delete This Secret Link Now'))
  end

  def test_deletable_by_viewer_falls_back_to_default
    get new_file_push_path
    assert_response :success

    post file_pushes_path, params: { 
      file_push: { 
        payload: 'æ ¼ ö ç ý',
        files: [ 
          fixture_file_upload('monkey.png', 'image/jpeg')
        ]
      }
    }
    assert_response :redirect

    follow_redirect!
    assert_response :success

    # Password page
    get request.url.sub('/preview', '')
    assert_response :success

    delete_button = css_select 'button.btn-danger'

    # HTML Form Checkboxes: when NOT checked the form attribute isn't submitted
    # at all so we set false - NOT deletable by viewers
    assert(delete_button.empty?)
  end
end
