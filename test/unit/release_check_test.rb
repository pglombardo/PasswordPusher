# frozen_string_literal: true

require "test_helper"

class ReleaseCheckTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    @original_check_for_updates = Settings.check_for_updates
  end

  teardown do
    Settings.check_for_updates = @original_check_for_updates
    Settings.reload!
  end

  test "request uses the dedicated user agent and no query parameters" do
    uri = ReleaseCheck.feed_uri

    assert_equal "docs.pwpush.com", uri.host
    assert_equal "/releases/oss.json", uri.path
    assert_nil uri.query

    request = ReleaseCheck.build_request(uri)
    assert_equal "PasswordPusher-UpdateCheck", request["User-Agent"]
    assert_equal uri.request_uri, request.path
    assert_nil URI(request.path).query
  end

  test "stores newer releases when the feed latest is ahead of the running version" do
    Version.stub :current, "1.0.0" do
      stub_feed(latest: "1.2.0", releases: [release("1.2.0"), release("1.1.0"), release("1.0.0")]) do
        result = ReleaseCheck.refresh

        assert_equal "1.2.0", result.latest
        assert result.update_available?
        assert_not result.security_available?
        assert_equal ["1.2.0", "1.1.0"], result.pending_releases.map { |item| item["version"] }
        assert_equal "https://github.com/pglombardo/PasswordPusher/releases/tag/v1.2.0", result.notes_url
        assert_equal result.latest, ReleaseCheck.cached.latest
      end
    end
  end

  test "does not treat the same version as an update" do
    Version.stub :current, "1.2.0" do
      stub_feed(latest: "1.2.0", releases: [release("1.2.0")]) do
        result = ReleaseCheck.refresh

        assert_equal "1.2.0", result.latest
        assert_not result.update_available?
        assert_empty result.pending_releases
      end
    end
  end

  test "does not treat an older feed latest as an update" do
    Version.stub :current, "2.0.0" do
      stub_feed(latest: "1.9.9", releases: [release("1.9.9")]) do
        result = ReleaseCheck.refresh

        assert_equal "1.9.9", result.latest
        assert_not result.update_available?
        assert_empty result.pending_releases
      end
    end
  end

  test "flags security when any newer release is marked security" do
    Version.stub :current, "1.0.0" do
      stub_feed(
        latest: "1.2.0",
        releases: [
          release("1.2.0"),
          release("1.1.0", security: true, severity: "high"),
          release("1.0.0")
        ]
      ) do
        result = ReleaseCheck.refresh

        assert result.update_available?
        assert result.security_available?
        assert result.pending_releases.any? { |item| item["security"] }
      end
    end
  end

  test "fails silently on malformed JSON and keeps the previous cache" do
    Version.stub :current, "1.0.0" do
      stub_feed(latest: "1.1.0") { ReleaseCheck.refresh }
      assert_equal "1.1.0", ReleaseCheck.cached.latest

      warnings = capture_warnings do
        ReleaseCheck.stub :http_get_body, "{not-json" do
          result = ReleaseCheck.refresh
          assert_equal "1.1.0", result.latest
        end
      end

      assert_match(/ReleaseCheck: update check failed/, warnings.join)
      assert_no_match(/ERROR/, warnings.join)
    end
  end

  test "fails silently on a timeout" do
    warnings = capture_warnings do
      ReleaseCheck.stub :http_get_body, -> { raise Net::OpenTimeout, "execution expired" } do
        assert_nil ReleaseCheck.refresh
      end
    end

    assert_match(/Net::OpenTimeout/, warnings.join)
    assert_nil ReleaseCheck.cached
  end

  test "fails silently when the response exceeds the size cap" do
    huge = "x" * (ReleaseCheck::MAX_BODY_BYTES + 1)

    warnings = capture_warnings do
      ReleaseCheck.stub :http_get_body, huge do
        assert_nil ReleaseCheck.refresh
      end
    end

    assert_match(/ReleaseCheck: update check failed/, warnings.join)
    assert_nil ReleaseCheck.cached
  end

  test "does not fetch when update checks are disabled" do
    Settings.check_for_updates = false

    ReleaseCheck.stub :http_get_body, -> { flunk "HTTP should not be called when disabled" } do
      assert_nil ReleaseCheck.refresh
    end
  end

  test "enabled follows the check_for_updates setting" do
    Settings.check_for_updates = true
    assert ReleaseCheck.enabled?

    Settings.check_for_updates = false
    assert_not ReleaseCheck.enabled?
  end

  test "ignores javascript notes URLs" do
    Version.stub :current, "1.0.0" do
      stub_feed(latest: "1.1.0", releases: [release("1.1.0", notes_url: "javascript:alert(1)")]) do
        result = ReleaseCheck.refresh
        assert_equal ReleaseCheck::DEFAULT_NOTES_URL, result.notes_url
        assert_nil result.pending_releases.first["notes_url"]
      end
    end
  end

  private

  def release(version, security: false, severity: nil, notes_url: "https://github.com/pglombardo/PasswordPusher/releases/tag/v#{version}")
    {
      "version" => version,
      "date" => "2026-11-26",
      "security" => security,
      "severity" => severity,
      "title" => "Release #{version}",
      "summary" => "Summary for #{version}",
      "notes_url" => notes_url,
      "upgrade_notes_url" => nil,
      "min_upgrade_from" => nil
    }
  end

  def stub_feed(latest:, releases: nil, &)
    payload = {
      "schema" => 1,
      "product" => "oss",
      "generated_at" => "2026-11-27T00:00:00Z",
      "latest" => latest,
      "stable" => latest,
      "releases" => releases || [release(latest)]
    }.to_json

    ReleaseCheck.stub :http_get_body, payload, &
  end

  def capture_warnings
    messages = []
    logger = Logger.new(StringIO.new)
    logger.define_singleton_method(:warn) { |message| messages << message.to_s }
    logger.define_singleton_method(:error) { |message| messages << "ERROR #{message}" }

    original = Rails.logger
    Rails.logger = logger
    yield
    messages
  ensure
    Rails.logger = original
  end
end
