require 'test_helper'

class PasswordCreationTest < ActionDispatch::IntegrationTest
  def test_password_creation
    get "/"
    assert_response :success

    post "/p", :password => { payload: "testpw" }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_select "p", "Your password is..."
  end

  def test_json_password_creation
    get "/"
    assert_response :success

    post "/p.json", :password => { payload: "testpw" }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("id")
    assert res.key?("payload")
    assert res.key?("url_token")
    assert res.key?("expired")
    assert_equal false, res["expired"]
    assert res.key?("deleted")
    assert_equal false, res["deleted"]
    assert res.key?("deletable_by_viewer")
    assert_equal false, res["deletable_by_viewer"]

    # Get the new password via json e.g. /p/<url_token>.json
    get "/p/" + res["url_token"] + ".json"
    assert_response :success
    res = JSON.parse(@response.body)
    assert res.key?("id")
    assert res.key?("payload")
    assert_equal "testpw", res["payload"]
    assert res.key?("url_token")
    assert res.key?("expired")
    assert_equal false, res["expired"]
    assert res.key?("deleted")
    assert_equal false, res["deleted"]
    assert res.key?("deletable_by_viewer")
    assert_equal false, res["deletable_by_viewer"]
  end
end
