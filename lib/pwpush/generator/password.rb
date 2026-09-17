# frozen_string_literal: true

module Pwpush
  module Generator
    class Password
      def initialize(length:, uppercase:, lowercase:, digits:, symbols:, avoid_ambiguous:, min_digits:, min_symbols:, charset:)
        @length = length
        @uppercase = uppercase
        @lowercase = lowercase
        @digits = digits
        @symbols = symbols
        @avoid_ambiguous = avoid_ambiguous
        @min_digits = digits ? min_digits : 0
        @min_symbols = symbols ? min_symbols : 0
        @charset = charset
        @pool = Charsets.pool(
          uppercase: @uppercase,
          lowercase: @lowercase,
          digits: @digits,
          symbols: @symbols,
          charset: @charset,
          avoid_ambiguous: @avoid_ambiguous
        )
        @classes = Charsets.class_pools(
          uppercase: @uppercase,
          lowercase: @lowercase,
          digits: @digits,
          symbols: @symbols,
          charset: @charset,
          avoid_ambiguous: @avoid_ambiguous
        )
        validate_minimums!
      end

      def generate
        chars = Array.new(@length) { sample(@pool) }
        enforce_classes!(chars)
        chars.join
      end

      def entropy_bits
        (@length * Math.log2(@pool.size)).round(1)
      end

      private

      def validate_minimums!
        required = @classes.size
        required += [@min_digits - 1, 0].max if @digits
        required += [@min_symbols - 1, 0].max if @symbols
        if required > @length
          raise InvalidParameter, "Password length is too short for the selected character rules."
        end
      end

      def enforce_classes!(chars)
        positions = secure_shuffle((0...@length).to_a)

        @classes.each_value do |pool|
          index = positions.shift
          chars[index] = sample(pool)
        end

        extra_digits = extra_count(@min_digits, :digits)
        extra_digits.times do
          index = positions.shift
          chars[index] = sample(Charsets.maybe_strip(Charsets::DIGITS, @avoid_ambiguous))
        end

        extra_symbols = extra_count(@min_symbols, :symbols)
        extra_symbols.times do
          index = positions.shift
          chars[index] = sample(Charsets::SYMBOLS)
        end
      end

      def extra_count(minimum, key)
        return 0 if minimum <= 1
        return 0 unless @classes.key?(key)

        [minimum - 1, 0].max
      end

      def sample(pool)
        pool[SecureRandom.random_number(pool.size)]
      end

      def secure_shuffle(list)
        list.size.times do |index|
          swap = index + SecureRandom.random_number(list.size - index)
          list[index], list[swap] = list[swap], list[index]
        end
        list
      end
    end
  end
end
