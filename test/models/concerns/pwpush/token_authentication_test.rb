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

  test "as_json omits token material even when only or methods request it" do
    json = @user.as_json(only: [:email, :authentication_token_digest, :authentication_token_hint])

    assert json.key?("email")
    assert_not json.key?("authentication_token")
    assert_not json.key?("authentication_token_digest")
    assert_not json.key?("authentication_token_hint")

    token = @user.regenerate_authentication_token!
    json = @user.as_json(methods: [:authentication_token])

    assert_not json.key?("authentication_token")
    assert_not json.key?("authentication_token_digest")
    assert_not json.key?("authentication_token_hint")
    assert_no_match(/#{Regexp.escape(token)}/, json.to_json)
  end

  test "inspect does not include the raw token" do
    @user.update!(authentication_token: "should-not-appear-in-inspect")

    assert_no_match(/should-not-appear-in-inspect/, @user.inspect)
  end

  test "hint_for omits tokens of 4 characters or fewer" do
    assert_nil Pwpush::AuthenticationTokenDigest.hint_for("2014")
    assert_nil Pwpush::AuthenticationTokenDigest.hint_for("abc")
    assert_equal "bcde", Pwpush::AuthenticationTokenDigest.hint_for("abcde")
  end

  test "short tokens authenticate without storing the full credential as a hint" do
    user = users(:giuliana)

    assert_nil user.authentication_token_hint
    assert_equal "••••", user.masked_authentication_token
    assert_equal user, User.find_by_authentication_token("2014")
  end

  test "tokens still authenticate after secret_key_base changes" do
    token = api_token_for(@user)
    digest_before = User.digest_authentication_token(token)
    original_key = Rails.application.secret_key_base
    new_key = SecureRandom.hex(64)

    Rails.application.stub(:secret_key_base, new_key) do
      assert_not_equal original_key, Rails.application.secret_key_base
      assert_equal digest_before, User.digest_authentication_token(token)
      assert_equal OpenSSL::Digest::SHA256.hexdigest(token), User.digest_authentication_token(token)
      assert_equal @user, User.find_by_authentication_token(token)
    end
  end
end
