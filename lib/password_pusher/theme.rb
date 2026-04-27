# frozen_string_literal: true

module PasswordPusher
  # Bootswatch theme slugs shipped under app/assets/stylesheets/themes/*.css
  # (built to app/assets/builds/application-<slug>.css by build_themes.js).
  module Theme
    DEFAULT_SLUG = "default"

    def self.available_slugs
      @available_slugs ||= begin
        dir = Rails.root.join("app/assets/stylesheets/themes")
        Dir.glob(dir.join("*.css").to_s).map { |p| File.basename(p, ".css") }
          .reject { |s| s == "selected" }
          .sort
      end
    end

    def self.slug_for_env
      raw = ENV.fetch("PWP__THEME", DEFAULT_SLUG).to_s.strip.downcase
      return DEFAULT_SLUG if raw.blank?

      if available_slugs.include?(raw)
        raw
      else
        Rails.logger&.warn(
          "[PasswordPusher] Unknown PWP__THEME=#{raw.inspect}; using #{DEFAULT_SLUG}. " \
          "Valid themes: #{available_slugs.join(", ")}"
        )
        DEFAULT_SLUG
      end
    end

    def self.stylesheet_logical_name
      "application-#{slug_for_env}"
    end
  end
end
