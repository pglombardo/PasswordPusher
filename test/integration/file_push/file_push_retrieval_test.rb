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

  def test_anonymous_retrieval
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

    #################################################
    # Sign out to test anonymous retrieval
    #################################################
    sign_out :user

    # File Push page accessible anonymously?
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

    # Is Preliminary page accessible anonymously?
    get request.url + '/r'
    assert_response :success

    links = css_select 'a'
    assert(links)
    assert_equal 1, links.length
    assert_equal "Click Here to Proceed", links.first.content
  end
end