# frozen_string_literal: true

require "test_helper"

class ReleaseCheckTest < ActiveSupport::TestCase
  include ReleaseCheckHTTPStub

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

  test "http_get_body returns the response body as a String" do
    payload = feed_json(latest: "2.17.5")

    stub_release_check_http(body: payload) do
      body = ReleaseCheck.http_get_body

      assert_instance_of String, body
      assert_equal payload, body
    end
  end

  test "http_get_body discards a partial body if Net::HTTP retries" do
    payload = feed_json(latest: "2.17.5")

    stub_release_check_http(body: payload, retry_body: '{"partial":true') do
      body = ReleaseCheck.http_get_body

      assert_equal payload, body
    end
  end

  test "perform parses latest and releases from a realistic oss.json feed" do
    Version.stub :current, "2.17.0" do
      stub_release_check_http(body: realistic_feed_json) do
        result = ReleaseCheck.new.perform

        assert_equal "2.17.5", result.latest
        assert_equal "2.17.0", result.current
        assert result.update_available?
        assert result.security_available?
        assert_equal ["2.17.5", "2.17.4", "2.17.3"], result.pending_releases.map { |item| item["version"] }
        security = result.pending_releases.find { |item| item["version"] == "2.17.4" }
        assert_equal true, security["security"]
        assert_equal "high", security["severity"]
        assert_equal "v2.17.4: Security - Update to Ruby 4.0.10", security["title"]
        assert_match(/Ruby 4.0.10/, security["summary"])
        assert_equal "https://github.com/pglombardo/PasswordPusher/releases/tag/v2.17.4", security["notes_url"]
        assert_equal "2026-11-19", security["date"]
        assert_equal "https://github.com/pglombardo/PasswordPusher/releases/tag/v2.17.5", result.notes_url
      end
    end
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
        stub_release_check_http(body: "{not-json") do
          result = ReleaseCheck.refresh
          assert_equal "1.1.0", result.latest
        end
      end

      assert_match(/ReleaseCheck: update check failed/, warnings.join)
      assert_no_match(/ERROR/, warnings.join)
    end
  end

  test "fails silently on a payload that is not a valid release feed" do
    [
      [{"schema" => 1}].to_json,
      {"schema" => 1, "product" => "oss"}.to_json,
      {"schema" => 1, "latest" => 2}.to_json,
      {"schema" => 1, "latest" => "not-a-version"}.to_json
    ].each do |body|
      Rails.cache.clear
      warnings = capture_warnings do
        stub_release_check_http(body: body) do
          assert_nil ReleaseCheck.refresh, "expected refresh to fail for #{body}"
        end
      end

      assert_match(/ReleaseCheck: update check failed/, warnings.join)
      assert_nil ReleaseCheck.cached
    end
  end

  test "fails silently on a non-2xx response" do
    warnings = capture_warnings do
      stub_release_check_http(body: "nope", code: "503") do
        assert_nil ReleaseCheck.refresh
      end
    end

    assert_match(/unexpected HTTP 503/, warnings.join)
    assert_nil ReleaseCheck.cached
  end

  test "fails silently on a timeout" do
    warnings = capture_warnings do
      stub_release_check_http(error: Net::OpenTimeout.new("execution expired")) do
        assert_nil ReleaseCheck.refresh
      end
    end

    assert_match(/Net::OpenTimeout/, warnings.join)
    assert_nil ReleaseCheck.cached
  end

  test "fails silently on a connection error" do
    warnings = capture_warnings do
      stub_release_check_http(error: SocketError.new("Failed to open TCP connection")) do
        assert_nil ReleaseCheck.refresh
      end
    end

    assert_match(/SocketError/, warnings.join)
    assert_nil ReleaseCheck.cached
  end

  test "fails silently when the Content-Length header exceeds the size cap" do
    warnings = capture_warnings do
      stub_release_check_http(body: "{}", content_length: ReleaseCheck::MAX_BODY_BYTES + 1) do
        assert_nil ReleaseCheck.refresh
      end
    end

    assert_match(/response too large/, warnings.join)
    assert_nil ReleaseCheck.cached
  end

  test "fails silently when streamed chunks exceed the size cap" do
    chunk = "x" * 1_000
    chunks = Array.new((ReleaseCheck::MAX_BODY_BYTES / chunk.bytesize) + 2, chunk)

    warnings = capture_warnings do
      stub_release_check_http(body: "", content_length: nil, chunks: chunks) do
        assert_nil ReleaseCheck.refresh
      end
    end

    assert_match(/response too large/, warnings.join)
    assert_nil ReleaseCheck.cached
  end

  test "does not fetch when update checks are disabled" do
    Settings.check_for_updates = false

    Net::HTTP.stub :new, ->(*) { flunk "HTTP should not be called when disabled" } do
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

  test "success notice when an update is available" do
    result = ReleaseCheck::Result.new(
      latest: "9.0.0",
      current: "1.0.0",
      newer_releases: [{"version" => "9.0.0", "security" => false}],
      security_available: false,
      checked_at: Time.current.iso8601,
      notes_url: ReleaseCheck::DEFAULT_NOTES_URL
    )

    Version.stub :current, "1.0.0" do
      assert_equal "Update check complete: version v9.0.0 is available.",
        ReleaseCheck.success_notice(result)
    end
  end

  test "success notice when already on the latest version" do
    result = ReleaseCheck::Result.new(
      latest: "2.17.5",
      current: "2.17.5",
      newer_releases: [],
      security_available: false,
      checked_at: Time.current.iso8601,
      notes_url: ReleaseCheck::DEFAULT_NOTES_URL
    )

    Version.stub :current, "2.17.5" do
      assert_equal "Update check complete: you're running the latest version (v2.17.5).",
        ReleaseCheck.success_notice(result)
    end
  end

  test "refresh persists when Rails.cache is a NullStore" do
    ReleaseCheck.clear_file_store

    Rails.stub :cache, ActiveSupport::Cache::NullStore.new do
      Version.stub :current, "1.0.0" do
        stub_feed(latest: "1.2.0") do
          result = ReleaseCheck.refresh

          assert_equal "1.2.0", result.latest
          assert_equal "1.2.0", ReleaseCheck.cached.latest
          assert_nil Rails.cache.read(ReleaseCheck::CACHE_KEY)
        end
      end
    end
  ensure
    ReleaseCheck.clear_file_store
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

  def feed_json(latest:, releases: nil)
    {
      "schema" => 1,
      "product" => "oss",
      "generated_at" => "2026-11-27T00:00:00Z",
      "latest" => latest,
      "stable" => latest,
      "releases" => releases || [release(latest)]
    }.to_json
  end

  def realistic_feed_json
    {
      "schema" => 1,
      "product" => "oss",
      "generated_at" => "2026-11-26T20:37:30-05:00",
      "latest" => "2.17.5",
      "stable" => "2.17.2",
      "releases" => [
        {
          "version" => "2.17.5",
          "date" => "2026-11-27",
          "security" => false,
          "severity" => nil,
          "title" => "v2.17.5: linux/arm64 Docker images are back",
          "summary" => "Restores official linux/arm64 Docker images for pwpush.",
          "notes_url" => "https://github.com/pglombardo/PasswordPusher/releases/tag/v2.17.5",
          "upgrade_notes_url" => nil,
          "min_upgrade_from" => nil
        },
        {
          "version" => "2.17.4",
          "date" => "2026-11-19",
          "security" => true,
          "severity" => "high",
          "title" => "v2.17.4: Security - Update to Ruby 4.0.10",
          "summary" => "Security update to Ruby 4.0.10, fixing regexp-engine vulnerabilities.",
          "notes_url" => "https://github.com/pglombardo/PasswordPusher/releases/tag/v2.17.4",
          "upgrade_notes_url" => nil,
          "min_upgrade_from" => nil
        },
        {
          "version" => "2.17.3",
          "date" => "2026-11-16",
          "security" => false,
          "severity" => nil,
          "title" => "v2.17.3: Dependency & Security Updates",
          "summary" => "Dependency updates and Hatchbox deploy script moves.",
          "notes_url" => "https://github.com/pglombardo/PasswordPusher/releases/tag/v2.17.3",
          "upgrade_notes_url" => nil,
          "min_upgrade_from" => nil
        },
        {
          "version" => "2.17.0",
          "date" => "2026-10-28",
          "security" => false,
          "severity" => nil,
          "title" => "v2.17.0: New SMTP SSL flag",
          "summary" => "Adds an smtp_ssl setting for implicit TLS.",
          "notes_url" => "https://github.com/pglombardo/PasswordPusher/releases/tag/v2.17.0",
          "upgrade_notes_url" => nil,
          "min_upgrade_from" => nil
        }
      ]
    }.to_json
  end

  def stub_feed(latest:, releases: nil, &)
    stub_release_check_http(body: feed_json(latest: latest, releases: releases), &)
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
