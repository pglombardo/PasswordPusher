# frozen_string_literal: true

require "test_helper"

class Pwpush::TokenAuthenticationTest < ActiveSupport::TestCase
  setup do
    @user = users(:luca)
  end

  test "fixture tokens authenticate by digest and not by plaintext column" do
    token = api_token_for(@user)

    assert_nil @user.read_attribute(:authentication_token)
    assert_nil User.find_by(authentication_token: token)
    assert_equal @user, User.find_by_authentication_token(token)
  end

  test "assigning authentication_token stores a digest and leaves plaintext null" do
    @user.update!(authentication_token: "fresh-token-value")
    @user.reload

    assert_nil @user.read_attribute(:authentication_token)
    assert_equal User.digest_authentication_token("fresh-token-value"), @user.authentication_token_digest
    assert_equal "alue", @user.authentication_token_hint
    assert_not @user.authentication_token_legacy?
    assert_equal @user, User.find_by_authentication_token("fresh-token-value")
  end

  test "regenerate_authentication_token! returns the new token and invalidates the old one" do
    old_token = api_token_for(@user)
    new_token = @user.regenerate_authentication_token!

    assert_not_equal old_token, new_token
    assert_nil @user.reload.read_attribute(:authentication_token)
    assert_nil User.find_by_authentication_token(old_token)
    assert_equal @user, User.find_by_authentication_token(new_token)
    assert_not @user.authentication_token_legacy?
  end

  test "find_by_authentication_token rejects a wrong token" do
    assert_nil User.find_by_authentication_token("definitely-wrong")
    assert_nil User.find_by_authentication_token("")
    assert_nil User.find_by_authentication_token(nil)
  end

  test "purge_authentication_token! clears the digest" do
    @user.purge_authentication_token!
    @user.reload

    assert_not @user.has_authentication_token?
    assert_nil @user.authentication_token_digest
    assert_nil @user.read_attribute(:authentication_token)
    assert_nil User.find_by_authentication_token(api_token_for(users(:luca)))
  end

  test "as_json omits token material" do
    json = @user.as_json

    assert_not json.key?("authentication_token")
    assert_not json.key?("authentication_token_digest")
    assert_not json.key?("authentication_token_hint")
  end

  test "inspect does not include the raw token" do
    @user.update!(authentication_token: "should-not-appear-in-inspect")

    assert_no_match(/should-not-appear-in-inspect/, @user.inspect)
  end

  test "PWPUSH_API_TOKEN_HMAC_KEY changes the digest independently of secret_key_base" do
    token = "same-token"
    default_digest = User.digest_authentication_token(token)
    ENV["PWPUSH_API_TOKEN_HMAC_KEY"] = "dedicated-hmac-key-for-tests"

    assert_not_equal default_digest, User.digest_authentication_token(token)
  ensure
    ENV.delete("PWPUSH_API_TOKEN_HMAC_KEY")
  end
end
