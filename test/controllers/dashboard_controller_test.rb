require 'test_helper'

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should redirect anonymous to user sign in' do
    get dashboard_active_path
    assert_response :redirect
    follow_redirect!
    assert response.body.include?('You need to sign in or sign up before continuing.')

    get dashboard_expired_path
    assert_response :redirect
    follow_redirect!
    assert response.body.include?('You need to sign in or sign up before continuing.')
  end

  test 'logged in users can access their dashboard' do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    get dashboard_active_path
    assert_response :success
    assert response.body.include?('You currently have no active pushes.')

    get dashboard_expired_path
    assert_response :success
    assert response.body.include?('You currently have no expired pushes.')
  end

  test 'logged in users with pushes can access their dashboard' do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    get new_password_path
    assert_response :success
    assert response.body.include?('Tip: Only enter a password into the box')

    post passwords_path params: {
      password: {
        payload: 'TCZHOiBJIGxlYXZlIHRoZXNlIGhpZGRlbiBtZXNzYWdlcyB0byB5b3UgYm90aCBzbyB0aGF0IHRoZXkgbWF5IGV4aXN0IGZvcmV2ZXIuIExvdmUgUGFwYS4='
      }
    }
    assert_response :redirect

    get dashboard_active_path
    assert_response :success
    assert !response.body.include?('You currently have no active pushes.')
  end

  test 'get active dashboard with token' do
    @luca = users(:luca)
    @luca.confirm

    get dashboard_active_path, headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }
    assert_response :success
  end

  test 'get expired dashboard with token' do
    @luca = users(:luca)
    @luca.confirm

    get dashboard_expired_path, headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }
    assert_response :success
  end
end
