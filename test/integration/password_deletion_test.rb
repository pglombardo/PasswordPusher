require 'test_helper'

class PasswordCreationTest < ActionDispatch::IntegrationTest
  def test_password_deletion
    get "/"
    assert_response :success

    post "/p", params: { :password => { payload: "testpw" } }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_select "p", "Your password is..."
  end
end
