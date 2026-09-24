# frozen_string_literal: true

module Pwpush
  module Generator
    module Charsets
      AMBIGUOUS = "Il1O0o"
      ASCII_LOWER = ("a".."z").to_a.join
      ASCII_UPPER = ("A".."Z").to_a.join
      DIGITS = ("0".."9").to_a.join
      SYMBOLS = "!@#$%^&*"
      PIN_DIGITS = DIGITS

      LATIN_LOWER = "àáâäæãåāèéêëēėęîïíīįìôöòóœøōõûüùúūÿñçß"
      LATIN_UPPER = "ÀÁÂÄÆÃÅĀÈÉÊËĒĖĘÎÏÍĪĮÌÔÖÒÓŒØŌÕÛÜÙÚŪŸÑÇ"
      CYRILLIC_LOWER = "абвгдежзийклмнопрстуфхцчшщъыьэюяё"
      CYRILLIC_UPPER = "АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯЁ"
      GREEK_LOWER = "αβγδεζηθικλμνξοπρστυφχψω"
      GREEK_UPPER = "ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ"

      module_function

      def pool(uppercase:, lowercase:, digits:, symbols:, charset:, avoid_ambiguous:)
        custom = charset.to_s
        if custom.present? && CHARSET_PRESETS.exclude?(custom)
          pool = custom.chars.uniq.join
          pool = strip_ambiguous(pool) if avoid_ambiguous
          raise InvalidParameter, I18n._("Character set is empty.") if pool.empty?

          return pool
        end

        parts = []
        parts << letters_for(charset, :lower) if lowercase
        parts << letters_for(charset, :upper) if uppercase
        parts << DIGITS if digits
        parts << SYMBOLS if symbols
        pool = parts.join.chars.uniq.join
        pool = strip_ambiguous(pool) if avoid_ambiguous
        raise InvalidParameter, I18n._("Select at least one character class.") if pool.empty?

        pool
      end

      def letters_for(charset, case_name)
        preset = charset.to_s.presence || "ascii"
        preset = "ascii" unless CHARSET_PRESETS.include?(preset)

        case [preset, case_name]
        when ["ascii", :lower] then ASCII_LOWER
        when ["ascii", :upper] then ASCII_UPPER
        when ["latin", :lower] then ASCII_LOWER + LATIN_LOWER
        when ["latin", :upper] then ASCII_UPPER + LATIN_UPPER
        when ["cyrillic", :lower] then CYRILLIC_LOWER
        when ["cyrillic", :upper] then CYRILLIC_UPPER
        when ["greek", :lower] then GREEK_LOWER
        when ["greek", :upper] then GREEK_UPPER
        else
          ASCII_LOWER
        end
      end

      def strip_ambiguous(pool)
        pool.chars.reject { |char| AMBIGUOUS.include?(char) }.join
      end

      def class_pools(uppercase:, lowercase:, digits:, symbols:, charset:, avoid_ambiguous:)
        custom = charset.to_s
        return {} if custom.present? && CHARSET_PRESETS.exclude?(custom)

        result = {}
        result[:lowercase] = maybe_strip(letters_for(charset, :lower), avoid_ambiguous) if lowercase
        result[:uppercase] = maybe_strip(letters_for(charset, :upper), avoid_ambiguous) if uppercase
        result[:digits] = maybe_strip(DIGITS, avoid_ambiguous) if digits
        result[:symbols] = SYMBOLS if symbols
        result.reject { |_key, value| value.blank? }
      end

      def maybe_strip(pool, avoid_ambiguous)
        avoid_ambiguous ? strip_ambiguous(pool) : pool
      end
    end
  end
end
