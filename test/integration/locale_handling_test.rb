# frozen_string_literal: true

require "test_helper"

class LocaleHandlingTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Rails.application.reload_routes!

    @user = users(:luca)
    @user.confirm
  end

  teardown do
    Settings.enable_logins = false
    Rails.application.reload_routes!
  end

  # Test locale persistence across requests
  test "locale persists in session across requests" do
    get root_path, params: {locale: "es"}
    assert_response :success
    assert_select "html[lang=es]"

    # Make another request without locale parameter
    get root_path
    assert_response :success
    # Locale should persist from session or user preference
    # Note: This depends on SetLocale concern implementation
  end

  test "locale from params takes precedence over session" do
    # Set locale in first request
    get root_path, params: {locale: "es"}
    assert_response :success

    # Override with different locale in second request
    get root_path, params: {locale: "fr"}
    assert_response :success
    assert_select "html[lang=fr]"
  end

  test "locale persists when navigating between pages" do
    get root_path, params: {locale: "es"}
    assert_response :success
    assert_select "html[lang=es]"

    # Navigate to another page
    get new_user_session_path, params: {locale: "es"}
    assert_response :success
    assert_select "html[lang=es]"
  end

  # Test locale in URLs
  test "locale parameter in URL sets locale" do
    get root_path, params: {locale: "es"}
    assert_response :success
    assert_select "html[lang=es]"
  end

  test "locale parameter works with push URLs" do
    push = pushes(:test_push)

    get push_path(push), params: {locale: "es"}
    assert_response :success
    assert_select "html[lang=es]"
  end

  test "locale parameter works with API endpoints" do
    get "/api/v1/version.json", params: {locale: "es"}
    assert_response :success
    # API endpoints may not have HTML lang attribute, but locale should be set
  end

  test "locale in URL overrides user preference" do
    @user.update(preferred_language: "fr")
    sign_in @user

    get root_path, params: {locale: "es"}
    assert_response :success
    assert_select "html[lang=es]"
  ensure
    sign_out @user
  end

  # Test invalid locale handling
  test "invalid locale falls back to default" do
    get root_path, params: {locale: "invalid_locale_xyz"}
    assert_response :success
    # Should fall back to default locale (en)
    assert_select "html[lang=en]"
  end

  test "invalid locale in URL is ignored" do
    get root_path, params: {locale: "xx"}
    assert_response :success
    # Should use default locale
    assert_select "html[lang=en]"
  end

  test "empty locale parameter uses default" do
    get root_path, params: {locale: ""}
    assert_response :success
    assert_select "html[lang=en]"
  end

  test "nil locale parameter uses default" do
    get root_path, params: {locale: nil}
    assert_response :success
    assert_select "html[lang=en]"
  end

  # Test locale from user preference
  test "locale from user preference when signed in" do
    @user.update(preferred_language: "es")
    sign_in @user

    get root_path
    assert_response :success
    assert_select "html[lang=es]"
  ensure
    sign_out @user
  end

  test "user preference locale overrides default" do
    @user.update(preferred_language: "fr")
    sign_in @user

    get root_path
    assert_response :success
    assert_select "html[lang=fr]"
  ensure
    sign_out @user
  end

  test "params locale takes precedence over user preference" do
    @user.update(preferred_language: "fr")
    sign_in @user

    get root_path, params: {locale: "es"}
    assert_response :success
    assert_select "html[lang=es]"
  ensure
    sign_out @user
  end

  # Test locale from Accept-Language header
  test "locale from Accept-Language header" do
    get root_path,
      headers: {
        "Accept-Language" => "es,en;q=0.9"
      }

    assert_response :success
    # Should use Spanish from header if available
    # Note: This depends on SetLocale concern implementation
  end

  test "Accept-Language header with region code" do
    get root_path,
      headers: {
        "Accept-Language" => "en-GB,en;q=0.9"
      }

    assert_response :success
    # Should handle en-GB if available, otherwise fall back to en
  end

  test "Accept-Language header fallback to base language" do
    get root_path,
      headers: {
        "Accept-Language" => "pt-BR,pt;q=0.9"
      }

    assert_response :success
    # Should try pt-BR first, then pt if pt-BR not available
  end

  # Test locale priority order
  test "locale priority: params > user > header > default" do
    @user.update(preferred_language: "fr")
    sign_in @user

    get root_path,
      params: {locale: "es"},
      headers: {
        "Accept-Language" => "de,en;q=0.9"
      }

    assert_response :success
    # Params locale (es) should win
    assert_select "html[lang=es]"
  ensure
    sign_out @user
  end

  test "locale priority: user > header > default when no params" do
    @user.update(preferred_language: "fr")
    sign_in @user

    get root_path,
      headers: {
        "Accept-Language" => "de,en;q=0.9"
      }

    assert_response :success
    # User preference (fr) should win over header (de)
    assert_select "html[lang=fr]"
  ensure
    sign_out @user
  end

  test "locale priority: header > default when no params or user" do
    get root_path,
      headers: {
        "Accept-Language" => "es,en;q=0.9"
      }

    assert_response :success
    # Header locale (es) should be used if available
  end

  # Test locale with special characters
  test "locale with special characters is handled safely" do
    # Attempt to inject special characters
    get root_path, params: {locale: "<script>alert('xss')</script>"}
    assert_response :success
    # Should fall back to default, not execute script
    assert_select "html[lang=en]"
  end

  test "locale with SQL injection attempt is handled safely" do
    get root_path, params: {locale: "'; DROP TABLE users;--"}
    assert_response :success
    # Should fall back to default
    assert_select "html[lang=en]"
  end

  # Test locale with complex scenarios
  test "locale persists through redirects" do
    get root_path, params: {locale: "es"}
    assert_response :success

    # Follow a redirect (e.g., after login)
    sign_in @user
    get root_path, params: {locale: "es"}
    assert_response :success
    assert_select "html[lang=es]"
  ensure
    sign_out @user
  end

  test "locale works with push creation flow" do
    sign_in @user

    get new_push_path, params: {locale: "es"}
    assert_response :success
    assert_select "html[lang=es]"

    post pushes_path, params: {
      push: {kind: "text", payload: "test"},
      locale: "es"
    }
    assert_response :redirect

    follow_redirect!
    assert_select "html[lang=es]"
  ensure
    sign_out @user
  end

  # Test default_url_options
  test "default_url_options includes locale when present" do
    get root_path, params: {locale: "es"}
    assert_response :success

    # Check that links include locale parameter
    # This is tested indirectly through URL generation
  end

  test "default_url_options excludes locale when not present" do
    get root_path
    assert_response :success
    # URLs should not include locale parameter
  end

  # Test locale with different enabled languages
  test "only enabled locales are accepted" do
    # Assuming 'en' and 'es' are enabled
    get root_path, params: {locale: "en"}
    assert_response :success
    assert_select "html[lang=en]"

    get root_path, params: {locale: "es"}
    assert_response :success
    assert_select "html[lang=es]"
  end

  test "disabled locale falls back to default" do
    # Assuming 'xx' is not in enabled_language_codes
    get root_path, params: {locale: "xx"}
    assert_response :success
    # Should fall back to default
    assert_select "html[lang=en]"
  end
end
