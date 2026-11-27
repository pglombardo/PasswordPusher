# frozen_string_literal: true

require "json"
require "net/http"

# Fetches the public OSS release feed and caches the comparison against this
# instance's version. Used by the daily job and the admin "Check now" action.
#
# The request sends no query parameters or instance identifiers.
class ReleaseCheck
  FEED_URL = "https://docs.pwpush.com/releases/oss.json"
  USER_AGENT = "PasswordPusher-UpdateCheck"
  TIMEOUT_SECONDS = 5
  MAX_BODY_BYTES = 64_000
  CACHE_KEY = "release_check"
  CACHE_TTL = 2.days
  DISMISS_COOKIE = "pwpush_dismissed_release"
  DEFAULT_NOTES_URL = "https://github.com/pglombardo/PasswordPusher/releases"

  Result = Data.define(:latest, :current, :newer_releases, :security_available, :checked_at, :notes_url) do
    def running_version
      Version.current.to_s
    end

    def update_available?
      ReleaseCheck.newer?(latest, running_version)
    end

    def security_available?
      pending_releases.any? { |release| release["security"] == true }
    end

    def pending_releases
      Array(newer_releases).select { |release| ReleaseCheck.newer?(release["version"], running_version) }
    end
  end

  class << self
    def enabled?
      Settings.check_for_updates != false
    end

    def cached
      result_from_cache(store.read(CACHE_KEY))
    end

    # Fetch the feed and store the result. Returns the cached result on
    # success, or the previous cache (possibly nil) when the fetch fails.
    def refresh
      return cached unless enabled?

      check_now
    rescue => e
      log_failure(e)
      cached
    end

    # Fetch and persist. Raises on failure so the admin Check now action can
    # show an error while still keeping any previously stored result.
    def check_now
      raise "update checks are disabled" unless enabled?

      result = new.perform
      raise "empty result" if result.nil?

      persist(result)
      result
    end

    def success_notice(result)
      if result.update_available?
        _("Update check complete: version v%{latest} is available.") % {latest: result.latest}
      else
        _("Update check complete: you're running the latest version (v%{version}).") % {version: result.running_version}
      end
    end

    def clear_file_store
      path = file_store_dir
      FileUtils.rm_rf(path) if path.exist?
      @file_store = nil
    end

    def newer?(candidate, baseline)
      candidate_version = parse_version(candidate)
      baseline_version = parse_version(baseline)
      return false if candidate_version.nil? || baseline_version.nil?

      candidate_version > baseline_version
    end

    def parse_version(value)
      text = value.to_s.strip.delete_prefix("v")
      return if text.blank?
      return unless Gem::Version.correct?(text)

      Gem::Version.new(text)
    end

    def log_failure(error)
      Rails.logger.warn("ReleaseCheck: update check failed (#{error.class}: #{error.message})")
    end

    private

    def persist(result)
      store.write(CACHE_KEY, result_to_cache(result), expires_in: CACHE_TTL)
    end

    # Development uses NullStore unless `bin/rails dev:cache` is on, which
    # would drop Check now results on redirect. Fall back to a small FileStore
    # under tmp/ so the last check survives without toggling cache.
    def store
      null_cache? ? file_store : Rails.cache
    end

    def null_cache?
      Rails.cache.is_a?(ActiveSupport::Cache::NullStore)
    end

    def file_store
      @file_store ||= ActiveSupport::Cache::FileStore.new(
        file_store_dir,
        race_condition_ttl: 10.seconds
      )
    end

    def file_store_dir
      dir = Rails.root.join("tmp", "cache", "release_check")
      worker = ENV["TEST_WORKER_NUMBER"]
      dir = dir.join("w#{worker}") if Rails.env.test? && worker.present?
      dir
    end

    def result_to_cache(result)
      {
        "latest" => result.latest,
        "current" => result.current,
        "newer_releases" => result.newer_releases,
        "security_available" => result.security_available,
        "checked_at" => result.checked_at,
        "notes_url" => result.notes_url
      }
    end

    def result_from_cache(raw)
      return unless raw.is_a?(Hash)

      data = raw.stringify_keys
      Result.new(
        latest: data["latest"],
        current: data["current"],
        newer_releases: Array(data["newer_releases"]),
        security_available: data["security_available"] == true,
        checked_at: data["checked_at"],
        notes_url: data["notes_url"]
      )
    end
  end

  def perform
    body = self.class.http_get_body
    raise "empty or oversized response" if body.blank? || body.bytesize > MAX_BODY_BYTES

    payload = parse_payload(body)
    raise "malformed release feed" if payload.nil?

    build_result(payload)
  end

  def self.http_get_body
    uri = feed_uri
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = TIMEOUT_SECONDS
    http.read_timeout = TIMEOUT_SECONDS
    http.write_timeout = TIMEOUT_SECONDS if http.respond_to?(:write_timeout=)

    # Net::HTTP#request with a block returns the response, not the block value.
    # Accumulate the body outside the block so callers receive a String.
    # Reset at the start of each yield so a Net::HTTP retry (max_retries is 1)
    # cannot append onto a partial previous body.
    body = +""
    http.request(build_request(uri)) do |response|
      body = +""
      unless response.is_a?(Net::HTTPSuccess)
        raise "unexpected HTTP #{response.code}"
      end

      if response.content_length && response.content_length > MAX_BODY_BYTES
        raise "response too large"
      end

      response.read_body do |chunk|
        body << chunk
        raise "response too large" if body.bytesize > MAX_BODY_BYTES
      end
    end
    body
  end

  def self.feed_uri
    uri = URI(FEED_URL)
    raise "feed URL must not include query parameters" unless uri.query.nil?

    uri
  end

  def self.build_request(uri)
    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = USER_AGENT
    request["Accept"] = "application/json"
    request
  end

  private

  def parse_payload(body)
    payload = JSON.parse(body)
    return unless payload.is_a?(Hash)
    return unless payload["latest"].is_a?(String)
    return unless self.class.parse_version(payload["latest"])

    payload
  rescue JSON::ParserError
    nil
  end

  def build_result(payload)
    current = Version.current.to_s
    latest = payload["latest"].to_s.strip.delete_prefix("v")
    newer_releases = sanitize_releases(payload["releases"], current)
    notes_url = safe_url(newer_releases.dig(0, "notes_url")) ||
      notes_url_for(payload["releases"], latest) ||
      DEFAULT_NOTES_URL

    Result.new(
      latest: latest,
      current: current,
      newer_releases: newer_releases,
      security_available: newer_releases.any? { |release| release["security"] == true },
      checked_at: Time.current.iso8601,
      notes_url: notes_url
    )
  end

  def sanitize_releases(releases, current)
    Array(releases).filter_map do |release|
      next unless release.is_a?(Hash)

      version = release["version"].to_s.strip.delete_prefix("v")
      next unless self.class.newer?(version, current)

      {
        "version" => version,
        "date" => release["date"].to_s.slice(0, 32).presence,
        "security" => release["security"] == true,
        "severity" => sanitize_severity(release["severity"]),
        "title" => release["title"].to_s.slice(0, 200).presence,
        "summary" => release["summary"].to_s.slice(0, 500).presence,
        "notes_url" => safe_url(release["notes_url"])
      }
    end
  end

  def notes_url_for(releases, latest)
    match = Array(releases).find do |release|
      release.is_a?(Hash) && release["version"].to_s.strip.delete_prefix("v") == latest
    end
    safe_url(match&.dig("notes_url"))
  end

  def sanitize_severity(value)
    severity = value.to_s.downcase
    return unless %w[low medium high critical].include?(severity)

    severity
  end

  def safe_url(value)
    uri = URI.parse(value.to_s)
    return unless uri.is_a?(URI::HTTP)
    return if uri.userinfo.present?

    uri.to_s
  rescue URI::InvalidURIError
    nil
  end
end
