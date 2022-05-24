require 'test_helper'

class PasswordControllerTest < ActionDispatch::IntegrationTest
  test 'New push form is available anonymous' do
    get new_password_path
    assert_response :success
    assert response.body.include?('Tip: Only enter a password into the box')
  end
end
