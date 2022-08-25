require 'test_helper'

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'get active dashboard via json with token' do
    Settings.enable_logins = true

    @luca = users(:luca)
    @luca.confirm

    # Post two passwords
    post passwords_path + '.json',
            params: { password: { payload: 'asdf 1', note: 'Test note 1' } },
            headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token },
            as: :json
    assert_response :created

    post passwords_path + '.json',
            params: { password: { payload: 'asdf 2', note: 'Always Try To Be Nice, But Never Fail To Be Kind.  :Doctor Who' } },
            headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token },
            as: :json
    assert_response :created

    get dashboard_active_path + '.json', headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }, as: :json
    assert_response :success
    pushes = Oj.load(response.body)
    
    assert pushes.count == 2
    assert pushes[0]["note"] == "Test note 1" || pushes[1]["note"] == "Test note 1"
    assert pushes[0].key?("payload") == false
    assert pushes[1].key?("payload") == false
  end

  test 'get expired dashboard via json with token' do
    Settings.enable_logins = true

    @luca = users(:luca)
    @luca.confirm

    # Post & expire two pushes
    post passwords_path + '.json',
            params: { password: { payload: 'asdf 1', note: 'Test note 1' } },
            headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token },
            as: :json
    assert_response :created
    push = Oj.load(response.body)

    delete password_path(id: push["url_token"]) + '.json',
            headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token },
            as: :json
    assert_response :success
    push = Oj.load(response.body)
    assert push["expired"] == true
    assert push.key?("payload") == false

    post passwords_path + '.json',
            params: { password: { payload: 'asdf 2', note: 'Rage, rage against the dying of the light.' } },
            headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token },
            as: :json
    assert_response :created
    push = Oj.load(response.body)

    delete password_path(id: push["url_token"]) + '.json',
            headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token },
            as: :json
    assert_response :success
    push = Oj.load(response.body)
    assert push["expired"] == true
    assert push.key?("payload") == false

    # Check Expired Dashboard
    get dashboard_expired_path + '.json', headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }, as: :json
    assert_response :success
    pushes = Oj.load(response.body)

    assert pushes.count == 2
    assert pushes[0]["note"] == "Test note 1" || pushes[1]["note"] == "Test note 1"
    assert pushes[0].key?("payload") == false
    assert pushes[1].key?("payload") == false
    assert pushes[0]["expired"] == true
    assert pushes[1]["expired"] == true
  end

  test 'get active dashboard via json with invalid token' do
    Settings.enable_logins = true

    @luca = users(:luca)
    @luca.confirm

    get dashboard_active_path + '.json', headers: { 'X-User-Email': @luca.email, 'X-User-Token': '546f4d79416d617a696e674769726c734c6561264769756c69616e612d494c6f7665596f75416c7761797326466f7265766572' }, as: :json
    assert_response :unauthorized

    pushes = Oj.load(response.body)
    assert pushes.key?("error")
    assert pushes["error"] == "You need to sign in or sign up before continuing."
  end

  test 'get expired dashboard via json with invalid token' do
    Settings.enable_logins = true

    @luca = users(:luca)
    @luca.confirm

    get dashboard_expired_path + '.json', headers: { 'X-User-Email': @luca.email, 'X-User-Token': 'MjIvOC8yMDIzLVdlSGFkQUdyZWF0RGF5QXRUaGVXYXRlclBhcmtJbkNlZmFsdQ==' }, as: :json
    assert_response :unauthorized

    pushes = Oj.load(response.body)
    assert pushes.key?("error")
    assert pushes["error"] == "You need to sign in or sign up before continuing."
  end
end