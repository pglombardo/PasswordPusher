# frozen_string_literal: true

require "test_helper"

class PasswordDeletionTest < ActionDispatch::IntegrationTest
  def test_anonymous_password_deletion
    assert Settings.pw.enable_deletable_pushes == true
    # create
    post pushes_path, params: {push: {kind: "text", payload: "testpw", deletable_by_viewer: "on"}}
    assert_response :redirect

    # preview
    follow_redirect!
    assert_response :success
    assert_select "h2", "Your push has been created."

    # view the push
    get request.url.sub("/preview", "")
    assert_response :success

    # Assert that the right password is in the page
    pre = css_select "pre"
    assert(pre)
    assert(pre.first.content.include?("testpw"))

    # Expire the push
    delete expire_push_path(request.url.match(/\/p\/(.*)/)[1])
    assert_response :redirect

    # Get redirected to the push that is now expired
    follow_redirect!
    assert_response :success
    assert response.body.include?("We apologize but this secret link has expired.")

    # Retrieve the preliminary page.  It should show expired too.
    get preliminary_push_path(Push.last)
    assert_response :success
    assert response.body.include?("We apologize but this secret link has expired.")
  end

  def test_delete_already_expired_goes_to_expired_path
    assert Settings.pw.enable_deletable_pushes == true
    # create
    post pushes_path, params: {push: {kind: "text", payload: "testpw", deletable_by_viewer: "on", expire_after_views: 1}}
    assert_response :redirect

    # preview
    follow_redirect!
    assert_response :success
    assert_select "h2", "Your push has been created."

    push_url = request.url.sub("/preview", "")

    # view the push
    get push_url
    assert_response :success

    # Assert that the right password is in the page
    pre = css_select "pre"
    assert(pre)
    assert(pre.first.content.include?("testpw"))

    # view the push again should give expired page
    get push_url
    assert_response :success

    expired_p = css_select "p.text-center"
    assert(expired_p)
    assert(expired_p.first.content.include?("We apologize but this secret link has expired."))

    # Delete the already expired push
    delete expire_push_path(request.url.match(/\/p\/(.*)/)[1])
    assert_response :redirect

    # Get redirected to the push that is now expired
    follow_redirect!
    assert_response :success
    assert response.body.include?("We apologize but this secret link has expired.")

    # Retrieve the preliminary page.  It should show expired too.
    get preliminary_push_path(Push.last)
    assert_response :success
    assert response.body.include?("We apologize but this secret link has expired.")
  end
end
