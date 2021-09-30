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

  test 'logged in gets the goods' do
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
end
