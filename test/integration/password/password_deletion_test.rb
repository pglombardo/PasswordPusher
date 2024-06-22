# frozen_string_literal: true

require "test_helper"

class PasswordCreationTest < ActionDispatch::IntegrationTest
  def test_anonymous_password_deletion
    assert Settings.pw.enable_deletable_pushes == true
    # create
    post passwords_path, params: {password: {payload: "testpw", deletable_by_viewer: "on"}}
    assert_response :redirect

    # preview
    follow_redirect!
    assert_response :success
    assert_select "h2", "Your push has been created."

    # view the password
    get request.url.sub("/preview", "")
    assert_response :success

    # Assert that the right password is in the page
    pre = css_select "pre"
    assert(pre)
    assert(pre.first.content.include?("testpw"))

    # Delete the passworda
    delete request.url
    assert_response :redirect

    # Get redirected to the password that is now expired
    follow_redirect!
    assert_response :success
    assert response.body.include?("We apologize but this secret link has expired.")

    # Retrieve the preliminary page.  It should show expired too.
    get preliminary_password_path(Password.last)
    assert_response :success
    assert response.body.include?("We apologize but this secret link has expired.")
  end
end
