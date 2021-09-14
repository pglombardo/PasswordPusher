require 'test_helper'

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should redirect anonymous to user sign in' do
    get dashboard_active_path
    assert_response :redirect
    assert response.body.include?('href="http://www.example.com/users/sign_in')

    get dashboard_expired_path
    assert_response :redirect
    assert response.body.include?('href="http://www.example.com/users/sign_in')
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
