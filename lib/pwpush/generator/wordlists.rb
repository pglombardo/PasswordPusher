# frozen_string_literal: true

require "zlib"

module Pwpush
  module Generator
    module Wordlists
      DIR = File.expand_path("wordlists", __dir__)

      module_function

      def words_for(language)
        lang = language.to_s
        raise InvalidParameter, I18n._("Unsupported language: %{language}") % {language: lang} unless LANGUAGES.include?(lang)

        cache[lang]
      end

      def size_for(language)
        words_for(language).size
      end

      def cache
        @cache ||= LANGUAGES.index_with { |lang| load_list(lang) }
      end

      def load_list(language)
        path = File.join(DIR, "#{language}.txt.gz")
        raise InvalidParameter, I18n._("Word list missing for %{language}") % {language: language} unless File.exist?(path)

        Zlib::GzipReader.open(path) do |gz|
          gz.read.split("\n").map { |word| word.unicode_normalize(:nfc) }.reject(&:blank?)
        end
      end
    end
  end
end
