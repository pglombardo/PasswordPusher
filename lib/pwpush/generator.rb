# frozen_string_literal: true

module Pwpush
  module Generator
    MAX_COUNT = 20
    MIN_PASSWORD_LENGTH = 4
    MAX_PASSWORD_LENGTH = 128
    MIN_PIN_LENGTH = 4
    MAX_PIN_LENGTH = 12
    MIN_WORD_COUNT = 3
    MAX_WORD_COUNT = 10
    TYPES = %w[password passphrase pin].freeze
    LANGUAGES = %w[en es fr de it].freeze
    CHARSET_PRESETS = %w[ascii latin cyrillic greek].freeze

    class Error < StandardError; end

    class InvalidParameter < Error; end

    def self.generate(**)
      Request.new(**).call
    end

    def self.supported_languages
      LANGUAGES
    end
  end
end
