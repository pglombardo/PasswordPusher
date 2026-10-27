# frozen_string_literal: true

require "test_helper"

class Pwpush::SmtpSettingsTest < ActiveSupport::TestCase
  MailSettings = Struct.new(
    :smtp_address,
    :smtp_port,
    :smtp_domain,
    :smtp_open_timeout,
    :smtp_read_timeout,
    :smtp_authentication,
    :smtp_user_name,
    :smtp_password,
    :smtp_openssl_verify_mode,
    :smtp_enable_starttls_auto,
    :smtp_starttls,
    :smtp_ssl,
    keyword_init: true
  )

  test "keeps STARTTLS auto when implicit TLS is off" do
    settings = Pwpush::SmtpSettings.build(mail_settings)

    assert_equal "smtp.example.com", settings[:address]
    assert_equal 587, settings[:port]
    assert_equal true, settings[:enable_starttls_auto]
    assert_nil settings[:ssl]
    assert_not settings.key?(:enable_starttls)
  end

  test "implicit TLS sets ssl and turns both STARTTLS modes off" do
    settings = Pwpush::SmtpSettings.build(mail_settings(
      smtp_port: 465,
      smtp_domain: "example.com",
      smtp_authentication: "plain",
      smtp_user_name: "apikey",
      smtp_password: "secret",
      smtp_open_timeout: 10,
      smtp_read_timeout: 10,
      smtp_enable_starttls_auto: true,
      smtp_starttls: true,
      smtp_ssl: true
    ))

    assert_equal "smtp.example.com", settings[:address]
    assert_equal 465, settings[:port]
    assert_equal "example.com", settings[:domain]
    assert_equal "plain", settings[:authentication]
    assert_equal "apikey", settings[:user_name]
    assert_equal "secret", settings[:password]
    assert_equal 10, settings[:open_timeout]
    assert_equal 10, settings[:read_timeout]
    assert_equal true, settings[:ssl]
    assert_equal false, settings[:enable_starttls_auto]
    assert_equal false, settings[:enable_starttls]
  end

  test "converts a symbol openssl verify mode to a string and leaves integers alone" do
    symbol_mode = Pwpush::SmtpSettings.build(mail_settings(smtp_openssl_verify_mode: :none))
    integer_mode = Pwpush::SmtpSettings.build(mail_settings(smtp_openssl_verify_mode: 0))

    assert_equal "none", symbol_mode[:openssl_verify_mode]
    assert_equal 0, integer_mode[:openssl_verify_mode]
  end

  private

  def mail_settings(overrides = {})
    MailSettings.new({
      smtp_address: "smtp.example.com",
      smtp_port: 587,
      smtp_enable_starttls_auto: true,
      smtp_ssl: false
    }.merge(overrides))
  end
end
