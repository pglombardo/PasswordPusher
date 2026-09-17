# frozen_string_literal: true

require "test_helper"

class ApiV2GenerateTest < ActionDispatch::IntegrationTest
  teardown do
    Settings.reload!
  end

  def test_generates_a_passphrase
    post "/api/v2/generate",
      params: {type: "passphrase", language: "en", word_count: 4, number: true},
      as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "passphrase", body["type"]
    assert_equal "en", body["language"]
    assert_equal 1, body["results"].size
    assert body["entropy_bits"].present?
    assert_match(/[0-9]{2}\z/, body["results"].first)
  end

  def test_passphrase_entropy_increases_with_word_count
    post "/api/v2/generate",
      params: {type: "passphrase", language: "en", word_count: 3, number: false, symbol: false},
      as: :json
    short_bits = JSON.parse(response.body)["entropy_bits"]

    post "/api/v2/generate",
      params: {type: "passphrase", language: "en", word_count: 10, number: false, symbol: false},
      as: :json
    long_bits = JSON.parse(response.body)["entropy_bits"]

    assert_operator long_bits, :>, short_bits
  end

  def test_generates_a_password_batch
    post "/api/v2/generate",
      params: {type: "password", length: 20, count: 3},
      as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 3, body["results"].size
    body["results"].each { |password| assert_equal 20, password.length }
  end

  def test_generates_a_pin
    post "/api/v2/generate",
      params: {type: "pin", length: 8},
      as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_match(/\A\d{8}\z/, body["results"].first)
  end

  def test_rejects_invalid_type
    post "/api/v2/generate",
      params: {type: "uuid"},
      as: :json

    assert_response :unprocessable_content
    body = JSON.parse(response.body)
    assert_match(/Unknown generator type/, body["error"])
  end

  def test_rejects_oversized_count
    post "/api/v2/generate",
      params: {type: "pin", count: 11},
      as: :json

    assert_response :unprocessable_content
  end

  def test_requires_authentication_when_anonymous_access_is_disabled
    Settings.allow_anonymous = false

    post "/api/v2/generate",
      params: {type: "pin"},
      as: :json

    assert_response :unauthorized
  end

  def test_accepts_bearer_token_when_anonymous_access_is_disabled
    Settings.allow_anonymous = false
    user = users(:one)

    post "/api/v2/generate",
      params: {type: "pin", length: 6},
      headers: {"Authorization" => "Bearer #{user.authentication_token}"},
      as: :json

    assert_response :success
  end

  def test_json_wrapper_keys_are_not_unpermitted
    previous = ActionController::Parameters.action_on_unpermitted_parameters
    ActionController::Parameters.action_on_unpermitted_parameters = :raise

    post "/api/v2/generate",
      params: {type: "passphrase", language: "it", word_count: 4, symbol: true},
      as: :json

    assert_response :success
  ensure
    ActionController::Parameters.action_on_unpermitted_parameters = previous
  end

  def test_rate_limits_generation
    30.times do
      post "/api/v2/generate", params: {type: "pin"}, as: :json
      assert_response :success
    end

    post "/api/v2/generate", params: {type: "pin"}, as: :json
    assert_response :too_many_requests
  end

  def test_help_api_page_documents_generate_endpoint
    get "/help/api"

    assert_response :success
    assert_includes response.body, "POST /api/v2/generate"
    assert_includes response.body, "password, passphrase, or pin"
    assert_includes response.body, "https://en.wikipedia.org/wiki/Password_strength#Entropy_as_a_measure_of_password_strength"
  end
end
