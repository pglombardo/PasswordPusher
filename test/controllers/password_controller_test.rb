# frozen_string_literal: true

require "test_helper"

class PasswordControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_file_pushes = false
    Settings.enable_url_pushes = false
    @luca = users(:luca)
  end

  teardown do
    Settings.enable_logins = false
    Settings.enable_file_pushes = false
    Settings.enable_url_pushes = false
  end

  test "New push form is available anonymous" do
    get new_push_path(tab: "text")
    assert_response :success
    assert response.body.include?("Tip: Only enter a password into the box")
  end

  test '"index" should redirect anonymous to user sign in' do
    get pushes_path
    assert_response :redirect
    follow_redirect!
    assert response.body.include?("You need to sign in or sign up before continuing.")
  end

  test "logged in users can access their dashboard" do
    sign_in @luca

    get pushes_path
    assert_response :success
    assert response.body.include?("You currently have no pushes.")

    get pushes_path(filter: "active")
    assert_response :success
    assert response.body.include?("You currently have no active pushes.")

    get pushes_path(filter: "expired")
    assert_response :success
    assert response.body.include?("You currently have no expired pushes.")
  end

  test "logged in users with pushes can access their dashboard" do
    sign_in @luca

    no_push_text = "You currently have no pushes."
    get pushes_path
    assert_response :success
    assert response.body.include?(no_push_text)

    get new_push_path(tab: "text")
    assert_response :success
    assert response.body.include?("Tip: Only enter a password into the box")

    # rubocop:disable Layout/LineLength
    post pushes_path params: {
      push: {
        kind: "text",
        payload: "TCZHOiBJIGxlYXZlIHRoZXNlIGhpZGRlbiBtZXNzYWdlcyB0byB5b3UgYm90aCBzbyB0aGF0IHRoZXkgbWF5IGV4aXN0IGZvcmV2ZXIuIExvdmUgUGFwYS4="
      }
    }
    # rubocop:enable Layout/LineLength
    assert_response :redirect

    get pushes_path
    assert_response :success
    assert_not response.body.include?(no_push_text)
  end

  test "get active dashboard with token" do
    get active_passwords_path(format: :json),
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success
  end

  test "get expired dashboard with token" do
    get expired_passwords_path(format: :json),
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success
  end

  test "active pagination limits" do
    # Sign in the user first
    sign_in @luca

    # Create 60 pushes to test pagination
    60.times do |i|
      post pushes_path, params: {
        push: {
          kind: "text",
          payload: "testpw#{i}"
        }
      }
      assert_response :redirect
    end

    # Test first page (should return 50 results)
    get active_passwords_path(format: :json),
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    assert_equal 50, res.count, "First page should return exactly 50 results"

    # Verify all results are active and not expired
    res.each do |push|
      assert_not push["expired"], "All results should be active"
      # Note: deleted field might not be present in OSS version
      assert push.key?("url_token"), "Each result should have a url_token"
    end

    # Test second page (should return remaining results)
    get active_passwords_path(format: :json, page: 2),
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res_page2 = JSON.parse(@response.body)
    assert res_page2.count <= 50, "Second page should return at most 50 results"
    assert res_page2.count > 0, "Second page should have some results"

    # Verify no overlap between pages
    first_page_tokens = res.map { |push| push["url_token"] }
    second_page_tokens = res_page2.map { |push| push["url_token"] }
    assert_empty first_page_tokens & second_page_tokens, "Pages should not have overlapping results"
  end

  test "expired pagination limits" do
    # Sign in the user first
    sign_in @luca

    # Create 60 pushes and immediately expire them
    60.times do |i|
      post pushes_path, params: {
        push: {
          kind: "text",
          payload: "testpw#{i}"
        }
      }
      assert_response :redirect

      # Get the created push and expire it
      push = Push.last
      push.expire!
    end

    # Test first page (should return 50 results)
    get expired_passwords_path(format: :json),
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    assert_equal 50, res.count, "First page should return exactly 50 results"

    # Verify all results are expired
    res.each do |push|
      assert push["expired"], "All results should be expired"
      # Note: deleted field might not be present in OSS version
      assert push.key?("url_token"), "Each result should have a url_token"
    end

    # Test second page (should return remaining results)
    get expired_passwords_path(format: :json, page: 2),
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res_page2 = JSON.parse(@response.body)
    assert res_page2.count <= 50, "Second page should return at most 50 results"
    assert res_page2.count > 0, "Second page should have some results"

    # Verify no overlap between pages
    first_page_tokens = res.map { |push| push["url_token"] }
    second_page_tokens = res_page2.map { |push| push["url_token"] }
    assert_empty first_page_tokens & second_page_tokens, "Pages should not have overlapping results"
  end

  test "page limit enforcement" do
    # Test page limit (200 pages max)
    get active_passwords_path(format: :json, page: 201),
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :bad_request

    res = JSON.parse(@response.body)
    assert res["error"].include?("Invalid page parameter"), "Should return invalid page parameter error"
  end

  test "invalid page parameter handling" do
    # Test negative page number (should default to 1)
    get active_passwords_path(format: :json, page: -1),
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.count <= 50, "Should return at most 50 results for invalid page"
  end

  test "malformed page parameter handling" do
    # Test non-numeric page parameter
    get active_passwords_path(format: :json, page: "abc"),
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :bad_request

    res = JSON.parse(@response.body)
    assert res["error"].include?("Invalid page parameter"), "Should return invalid page parameter error"
  end
end
