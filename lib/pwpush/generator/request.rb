# frozen_string_literal: true

module Pwpush
  module Generator
    class Request
      def initialize(**params)
        @params = params.with_indifferent_access
      end

      def call
        type = normalized_type
        count = normalized_count
        results = Array.new(count) { generate_one(type) }

        {
          type: type,
          language: (type == "passphrase") ? language : nil,
          entropy_bits: entropy_bits(type),
          results: results
        }.compact
      end

      private

      def generate_one(type)
        case type
        when "password" then Password.new(**password_options).generate
        when "passphrase" then Passphrase.new(**passphrase_options).generate
        when "pin" then Pin.new(**pin_options).generate
        end
      end

      def entropy_bits(type)
        case type
        when "password" then Password.new(**password_options).entropy_bits
        when "passphrase" then Passphrase.new(**passphrase_options).entropy_bits
        when "pin" then Pin.new(**pin_options).entropy_bits
        end
      end

      def normalized_type
        type = @params.fetch(:type, Settings.gen.default_type).to_s
        raise InvalidParameter, I18n._("Unknown generator type: %{type}") % {type: type} unless TYPES.include?(type)

        type
      end

      def normalized_count
        count = integer(@params.fetch(:count, 1), "count")
        raise InvalidParameter, I18n._("count must be between 1 and %{max}.") % {max: MAX_COUNT} unless count.between?(1, MAX_COUNT)

        count
      end

      def language
        lang = @params.fetch(:language, Settings.gen.language).to_s
        raise InvalidParameter, I18n._("Unsupported language: %{language}") % {language: lang} unless LANGUAGES.include?(lang)

        lang
      end

      def password_options
        password = Settings.gen.password
        {
          length: bounded_integer(@params.fetch(:length, password.character_length), "length", MIN_PASSWORD_LENGTH, MAX_PASSWORD_LENGTH),
          uppercase: boolean(@params.fetch(:uppercase, password.uppercase)),
          lowercase: boolean(@params.fetch(:lowercase, password.lowercase)),
          digits: boolean(@params.fetch(:digits, password.digits)),
          symbols: boolean(@params.fetch(:symbols, password.symbols)),
          avoid_ambiguous: boolean(@params.fetch(:avoid_ambiguous, password.avoid_ambiguous)),
          min_digits: non_negative_integer(@params.fetch(:min_digits, 1), "min_digits"),
          min_symbols: non_negative_integer(@params.fetch(:min_symbols, 1), "min_symbols"),
          charset: @params.fetch(:charset, password.charset).to_s
        }
      end

      def passphrase_options
        passphrase = Settings.gen.passphrase
        {
          language: language,
          word_count: bounded_integer(@params.fetch(:word_count, passphrase.word_count), "word_count", MIN_WORD_COUNT, MAX_WORD_COUNT),
          separator: @params.fetch(:separator, passphrase.separator).to_s,
          capitalize: boolean(@params.fetch(:capitalize, passphrase.capitalize)),
          number: boolean(@params.fetch(:number, passphrase.number)),
          symbol: boolean(@params.fetch(:symbol, passphrase.symbol))
        }
      end

      def pin_options
        {
          length: bounded_integer(@params.fetch(:length, Settings.gen.pin.digit_count), "length", MIN_PIN_LENGTH, MAX_PIN_LENGTH)
        }
      end

      def boolean(value)
        ActiveModel::Type::Boolean.new.cast(value)
      end

      def integer(value, name)
        Integer(value)
      rescue ArgumentError, TypeError
        raise InvalidParameter, I18n._("%{name} must be an integer.") % {name: name}
      end

      def non_negative_integer(value, name)
        number = integer(value, name)
        raise InvalidParameter, I18n._("%{name} must be zero or greater.") % {name: name} if number.negative?

        number
      end

      def bounded_integer(value, name, min, max)
        number = integer(value, name)
        raise InvalidParameter, I18n._("%{name} must be between %{min} and %{max}.") % {name: name, min: min, max: max} unless number.between?(min, max)

        number
      end
    end
  end
end
