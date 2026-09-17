# frozen_string_literal: true

require "test_helper"

class PwpushGeneratorTest < ActiveSupport::TestCase
  test "generates a random password with required character classes" do
    result = Pwpush::Generator.generate(type: "password", length: 16, count: 1)

    password = result[:results].first
    assert_equal "password", result[:type]
    assert_equal 16, password.length
    assert_match(/[A-Z]/, password)
    assert_match(/[a-z]/, password)
    assert_match(/[0-9]/, password)
    assert_match(/[!@#$%^&*]/, password)
    assert_operator result[:entropy_bits], :>, 50
  end

  test "password entropy accounts for enforced character classes" do
    naive = Pwpush::Generator.generate(type: "password", length: 8, min_digits: 1, min_symbols: 1)
    constrained = Pwpush::Generator.generate(type: "password", length: 8, min_digits: 3, min_symbols: 2)

    pool = Pwpush::Generator::Charsets.pool(
      uppercase: true, lowercase: true, digits: true, symbols: true, charset: "ascii", avoid_ambiguous: true
    )
    naive_ceiling = (8 * Math.log2(pool.size)).round(1)

    assert_operator naive[:entropy_bits], :<=, naive_ceiling
    assert_operator constrained[:entropy_bits], :<, naive[:entropy_bits]
  end

  test "omits ambiguous characters when requested" do
    20.times do
      password = Pwpush::Generator.generate(
        type: "password",
        length: 24,
        avoid_ambiguous: true
      )[:results].first
      assert_empty password.chars & Pwpush::Generator::Charsets::AMBIGUOUS.chars
    end
  end

  test "honors min_digits and min_symbols" do
    password = Pwpush::Generator.generate(
      type: "password",
      length: 12,
      min_digits: 3,
      min_symbols: 2
    )[:results].first

    assert_operator password.scan(/[0-9]/).size, :>=, 3
    assert_operator password.scan(/[!@#$%^&*]/).size, :>=, 2
  end

  test "generates passphrases from the requested language" do
    words = Pwpush::Generator::Wordlists.words_for("de")
    result = Pwpush::Generator.generate(
      type: "passphrase",
      language: "de",
      word_count: 4,
      separator: "-",
      capitalize: true,
      number: true,
      symbol: false
    )

    phrase = result[:results].first
    parts = phrase.sub(/\d{2}\z/, "").split("-")
    assert_equal "de", result[:language]
    assert_match(/\d{2}\z/, phrase)
    assert_equal 4, parts.size
    parts.each do |part|
      assert_includes words, part.downcase
      assert_equal part, part.capitalize
    end
  end

  test "appends a symbol to passphrases when requested" do
    phrase = Pwpush::Generator.generate(
      type: "passphrase",
      number: false,
      symbol: true
    )[:results].first
    assert_includes Pwpush::Generator::Charsets::SYMBOLS, phrase[-1]
  end

  test "generates numeric pins of the requested length" do
    result = Pwpush::Generator.generate(type: "pin", length: 6)
    pin = result[:results].first

    assert_equal 6, pin.length
    assert_match(/\A\d{6}\z/, pin)
  end

  test "batch generation returns the requested count" do
    result = Pwpush::Generator.generate(type: "pin", length: 4, count: 5)
    assert_equal 5, result[:results].size
    result[:results].each { |pin| assert_match(/\A\d{4}\z/, pin) }
  end

  test "rejects an oversized batch" do
    error = assert_raises(Pwpush::Generator::InvalidParameter) do
      Pwpush::Generator.generate(type: "pin", count: 11)
    end
    assert_match(/count/, error.message)
  end

  test "rejects unknown types and languages" do
    assert_raises(Pwpush::Generator::InvalidParameter) { Pwpush::Generator.generate(type: "uuid") }
    assert_raises(Pwpush::Generator::InvalidParameter) { Pwpush::Generator.generate(type: "passphrase", language: "ja") }
  end

  test "latin charset includes accented letters" do
    password = Pwpush::Generator.generate(
      type: "password",
      length: 48,
      charset: "latin",
      digits: false,
      symbols: false,
      avoid_ambiguous: false
    )[:results].first

    assert password.downcase.chars.any? { |char| Pwpush::Generator::Charsets::LATIN_LOWER.include?(char) }
  end

  test "loads all bundled word lists" do
    Pwpush::Generator::LANGUAGES.each do |language|
      words = Pwpush::Generator::Wordlists.words_for(language)
      assert_operator words.size, :>=, 2048, "#{language} word list is too small"
      assert_equal words.size, words.uniq.size
    end
  end
end
