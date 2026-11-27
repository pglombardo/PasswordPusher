# frozen_string_literal: true

require "test_helper"

class AuthenticationTokenManagementTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:luca)
  end

  def plaintext_column(user)
    user.reload.read_attribute(:authentication_token)
  end

  def revealed_token_from_page
    css_select("#authentication_token").text.strip
  end

  test "token page requires authentication" do
    get token_user_registration_path
    assert_redirected_to new_user_session_path
  end

  test "legacy token page shows hint and cannot display the full token" do
    sign_in @user

    get token_user_registration_path
    assert_response :success
    assert_select "h2", text: /API Token/
    assert_select "#legacy-token-notice"
    assert_select "#authentication_token_hint", text: /••••7890/
    assert_select "#authentication_token", count: 0
    assert_no_match(/1234567890/, @response.body)
    assert_nil plaintext_column(@user)
  end

  test "token page generates token when user has none" do
    @user.update(authentication_token: nil)
    sign_in @user

    get token_user_registration_path
    assert_response :success

    @user.reload
    assert @user.has_authentication_token?
    assert_nil plaintext_column(@user)
    assert_select "#authentication_token"
    assert_select "#token-shown-once-notice"
    token = revealed_token_from_page
    assert_not_equal "", token
    assert_equal @user, User.find_by_authentication_token(token)
  end

  test "token page generates token when token is blank" do
    @user.update(authentication_token: "")
    sign_in @user

    get token_user_registration_path
    assert_response :success

    @user.reload
    assert @user.has_authentication_token?
    assert_nil plaintext_column(@user)
    assert_not_equal "", revealed_token_from_page
  end

  test "token page shows regenerate button" do
    sign_in @user

    get token_user_registration_path
    assert_response :success
    assert_select "button", text: /Regenerate Token/
    assert_select "form[data-turbo=false][action=?]", token_user_registration_path do
      assert_select "button[type=submit]", text: /Delete & Regenerate/
    end
  end

  test "token page shows token security warning" do
    sign_in @user

    get token_user_registration_path
    assert_response :success
    assert_select "p", text: /keep this token secure/
  end

  test "regen_token requires authentication" do
    delete token_user_registration_path
    assert_redirected_to new_user_session_path
  end

  test "regen_token regenerates authentication token" do
    original_digest = @user.authentication_token_digest
    sign_in @user

    delete token_user_registration_path

    assert_response :success
    assert_select "#authentication_token"
    @user.reload
    assert_not_equal original_digest, @user.authentication_token_digest
    assert @user.has_authentication_token?
    assert_not @user.authentication_token_legacy?
    assert_nil plaintext_column(@user)
  end

  test "regen_token generates new unique token" do
    other_user = users(:giuliana)
    sign_in @user

    delete token_user_registration_path

    @user.reload
    other_user.reload
    assert_not_equal @user.authentication_token_digest, other_user.authentication_token_digest
  end

  test "regen_token renders the new token in the delete response" do
    sign_in @user

    delete token_user_registration_path

    assert_response :success
    assert_select "#authentication_token"
    assert_select "#token-shown-once-notice"
    assert_nil session[:raw_authentication_token]
  end

  test "regen_token invalidates old token" do
    original_token = api_token_for(@user)

    get "/p/active.json",
      headers: {
        "Authorization" => "Bearer #{original_token}",
        "Accept" => "application/json"
      }
    assert_response :success

    sign_in @user
    delete token_user_registration_path
    assert_response :success
    new_token = revealed_token_from_page
    sign_out @user

    get "/p/active.json",
      headers: {
        "Authorization" => "Bearer #{original_token}",
        "Accept" => "application/json"
      }
    assert_response :unauthorized

    get "/p/active.json",
      headers: {
        "Authorization" => "Bearer #{new_token}",
        "Accept" => "application/json"
      }
    assert_response :success
    assert_nil plaintext_column(@user)
  end

  test "regen_token works when user has no existing token" do
    @user.update(authentication_token: nil)
    sign_in @user

    delete token_user_registration_path

    @user.reload
    assert @user.has_authentication_token?
    assert_nil plaintext_column(@user)
  end

  test "token page uses application layout" do
    sign_in @user

    get token_user_registration_path
    assert_response :success
    assert_select "body"
  end

  test "token page shows copy button only when the full token is revealed" do
    sign_in @user

    get token_user_registration_path
    assert_response :success
    assert_select "[data-controller*='copy']", count: 0

    delete token_user_registration_path
    assert_response :success
    assert_select "[data-controller*='copy']"
  end

  test "revealed token is shown once then masked" do
    sign_in @user

    delete token_user_registration_path
    assert_response :success
    token = revealed_token_from_page
    assert_select "#token-shown-once-notice"
    assert_select ".spoiler"
    assert_nil session[:raw_authentication_token]
    assert_not session.to_hash.values.any? { |value| value.to_s.include?(token) }

    get token_user_registration_path
    assert_response :success
    assert_select "#authentication_token", count: 0
    assert_select "#authentication_token_hint"
    assert_select "#legacy-token-notice", count: 0
    assert_no_match(/#{Regexp.escape(token)}/, @response.body)
    assert_equal @user.reload, User.find_by_authentication_token(token)
  end

  test "short tokens do not leak the full credential as a hint" do
    user = users(:giuliana)
    sign_in user

    get token_user_registration_path
    assert_response :success
    assert_nil user.reload.authentication_token_hint
    assert_select "#authentication_token_hint", text: "••••"
    assert_no_match(/2014/, @response.body)
    assert_equal user, User.find_by_authentication_token("2014")
  end

  test "regenerated token is unique across all users" do
    users_with_tokens = []
    5.times do |i|
      user = User.create!(
        email: "test#{i}@example.com",
        password: "password12345",
        confirmed_at: Time.current
      )
      user.update(authentication_token: "token#{i}")
      users_with_tokens << user
    end

    sign_in @user

    delete token_user_registration_path

    @user.reload
    existing_digests = users_with_tokens.map { |user| user.reload.authentication_token_digest }
    assert_not_includes existing_digests, @user.authentication_token_digest
  ensure
    users_with_tokens.each(&:destroy)
  end

  test "token persists across page reloads" do
    sign_in @user

    get token_user_registration_path
    digest1 = @user.reload.authentication_token_digest

    get token_user_registration_path
    digest2 = @user.reload.authentication_token_digest

    assert_equal digest1, digest2
  end

  test "new token works with API immediately after regeneration" do
    sign_in @user

    delete token_user_registration_path
    assert_response :success
    new_token = revealed_token_from_page
    sign_out @user

    get "/p/active.json",
      headers: {
        "Authorization" => "Bearer #{new_token}",
        "Accept" => "application/json"
      }
    assert_response :success
  end
end
