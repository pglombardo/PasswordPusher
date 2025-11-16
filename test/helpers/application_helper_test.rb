# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  include ApplicationHelper

  setup do
    @push = pushes(:test_push)
    # Ensure Settings are available
    @original_title = Settings.brand.title
    @original_enabled_language_codes = Settings.enabled_language_codes.dup
    @original_override_base_url = Settings.override_base_url
  end

  teardown do
    # Restore original settings
    Settings.brand.title = @original_title
    Settings.enabled_language_codes = @original_enabled_language_codes
    Settings.override_base_url = @original_override_base_url
    ENV.delete("FORCE_SSL")
  end

  # Test title method
  test "title sets content with site identifier" do
    title("Test Page")
    assert_equal "Test Page | #{Settings.brand.title}", content_for(:html_title)
  end

  test "title with custom site title" do
    Settings.brand.title = "Custom Site"
    title("My Page")
    assert_equal "My Page | Custom Site", content_for(:html_title)
  end

  # Test plain_title method
  test "plain_title sets content without site identifier" do
    plain_title("Test Page")
    assert_equal "Test Page", content_for(:html_title)
  end

  test "plain_title does not include site branding" do
    Settings.brand.title = "Password Pusher"
    plain_title("Secret Password")
    assert_equal "Secret Password", content_for(:html_title)
    assert_not content_for(:html_title).include?("Password Pusher")
  end

  # Test current_controller? method
  test "current_controller? returns true when controller matches" do
    @controller.params = ActionController::Parameters.new(controller: "pushes")
    assert current_controller?(["pushes"])
    assert current_controller?(["pushes", "pages"])
  end

  test "current_controller? returns false when controller does not match" do
    @controller.params = ActionController::Parameters.new(controller: "pushes")
    assert_not current_controller?(["pages"])
    assert_not current_controller?(["admin", "users"])
  end

  test "current_controller? handles array of controller names" do
    @controller.params = ActionController::Parameters.new(controller: "pages")
    assert current_controller?(["pushes", "pages", "admin"])
    assert_not current_controller?(["pushes", "admin"])
  end

  # Test secret_url method
  test "secret_url generates standard push URL" do
    @push.retrieval_step = false
    url = secret_url(@push)
    assert url.include?(@push.url_token)
    assert url.start_with?("http")
  end

  test "secret_url generates preliminary URL when retrieval_step is enabled" do
    @push.retrieval_step = true
    url = secret_url(@push, with_retrieval_step: true)
    assert url.include?("/r")
    assert url.include?(@push.url_token)
  end

  test "secret_url skips retrieval step when with_retrieval_step is false" do
    @push.retrieval_step = true
    url = secret_url(@push, with_retrieval_step: false)
    assert_not url.include?("/r")
    assert url.include?(@push.url_token)
  end

  test "secret_url appends locale from params when present and enabled" do
    @controller.params = ActionController::Parameters.new("push_locale" => "en")
    Settings.enabled_language_codes = ["en", "es", "fr"]
    url = secret_url(@push)
    assert url.include?("locale=en")
  end

  test "secret_url appends locale parameter when provided" do
    Settings.enabled_language_codes = ["en", "es", "fr"]
    url = secret_url(@push, locale: "es")
    assert url.include?("locale=es")
  end

  test "secret_url prioritizes params locale over method locale" do
    @controller.params = ActionController::Parameters.new("push_locale" => "fr")
    Settings.enabled_language_codes = ["en", "es", "fr"]
    url = secret_url(@push, locale: "es")
    assert url.include?("locale=fr")
    assert_not url.include?("locale=es")
  end

  test "secret_url ignores invalid locale from params" do
    @controller.params = ActionController::Parameters.new("push_locale" => "invalid")
    Settings.enabled_language_codes = ["en", "es"]
    url = secret_url(@push)
    assert_not url.include?("locale=")
  end

  test "secret_url ignores invalid locale parameter" do
    Settings.enabled_language_codes = ["en", "es"]
    url = secret_url(@push, locale: "invalid")
    assert_not url.include?("locale=")
  end

  test "secret_url removes existing locale query parameter" do
    # Mock the route helper to return URL with existing locale
    def push_path(push)
      "/p/#{push.url_token}?locale=old"
    end

    def push_url(push)
      "http://test.host/p/#{push.url_token}?locale=old"
    end

    @controller.params = ActionController::Parameters.new("push_locale" => "en")
    Settings.enabled_language_codes = ["en", "es"]
    url = secret_url(@push)
    # Should only have one locale parameter
    assert_equal 1, url.scan("locale=").count
    assert url.include?("locale=en")
    assert_not url.include?("locale=old")
  end

  test "secret_url uses override_base_url when set" do
    Settings.override_base_url = "https://custom.example.com"
    url = secret_url(@push)
    assert url.start_with?("https://custom.example.com")
  end

  # Test qr_code method
  test "qr_code generates SVG QR code" do
    test_url = "https://example.com/test"
    qr = qr_code(test_url)
    assert qr.include?("<svg")
    assert qr.include?("xmlns")
    assert qr.html_safe?
  end

  test "qr_code generates valid SVG structure" do
    test_url = "https://pwpush.com/p/abc123"
    qr = qr_code(test_url)
    # Check for SVG structure
    assert_match(/<svg[^>]*>/, qr)
    assert_match(/<\/svg>/, qr)
  end

  test "qr_code handles different URL formats" do
    urls = [
      "https://example.com",
      "http://test.com/path",
      "https://pwpush.com/p/xyz789?locale=en"
    ]

    urls.each do |url|
      qr = qr_code(url)
      assert qr.include?("<svg"), "QR code should be SVG for URL: #{url}"
    end
  end

  test "qr_code returns html_safe string" do
    qr = qr_code("https://example.com")
    assert qr.html_safe?
    assert qr.is_a?(ActiveSupport::SafeBuffer)
  end
end
