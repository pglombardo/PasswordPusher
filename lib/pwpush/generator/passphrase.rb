# frozen_string_literal: true

require "securerandom"

module Pwpush
  module Generator
    class Passphrase
      def initialize(language:, word_count:, separator:, capitalize:, number:, symbol:)
        @language = language
        @word_count = word_count
        @separator = separator
        @capitalize = capitalize
        @number = number
        @symbol = symbol
        @words = Wordlists.words_for(@language)
        raise InvalidParameter, "Separator is too long." if @separator.length > 8
      end

      def generate
        picked = Array.new(@word_count) { sample_word }
        picked.map! { |word| @capitalize ? word.capitalize : word }
        phrase = picked.join(@separator)
        phrase += format("%02d", SecureRandom.random_number(100)) if @number
        phrase += sample_char(Charsets::SYMBOLS) if @symbol
        phrase
      end

      def entropy_bits
        bits = @word_count * Math.log2(@words.size)
        bits += Math.log2(100) if @number
        bits += Math.log2(Charsets::SYMBOLS.size) if @symbol
        bits.round(1)
      end

      private

      def sample_word
        @words[SecureRandom.random_number(@words.size)]
      end

      def sample_char(pool)
        pool[SecureRandom.random_number(pool.size)]
      end
    end
  end
end
