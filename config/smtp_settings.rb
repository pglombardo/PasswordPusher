# frozen_string_literal: true

# Required from config/environments/production.rb during boot, before Zeitwerk
# is set up. Keep this file outside the autoload paths.
module PasswordPusher
  # Builds the ActionMailer smtp_settings hash from Settings.mail.
  module SmtpSettings
    module_function

    def build(mail)
      settings = {
        address: mail.smtp_address,
        port: mail.smtp_port
      }

      settings[:domain] = mail.smtp_domain if mail.smtp_domain
      settings[:open_timeout] = mail.smtp_open_timeout if mail.smtp_open_timeout
      settings[:read_timeout] = mail.smtp_read_timeout if mail.smtp_read_timeout
      settings[:authentication] = mail.smtp_authentication unless mail.smtp_authentication.nil?
      settings[:user_name] = mail.smtp_user_name unless mail.smtp_user_name.nil?
      settings[:password] = mail.smtp_password unless mail.smtp_password.nil?

      # The mail gem maps String names ("none" / "peer") to OpenSSL::SSL::VERIFY_* constants.
      # A Symbol like :none raises TypeError during TLS handshake. Leave Integers alone —
      # config.env_parse_values can turn PWP__MAIL__SMTP_OPENSSL_VERIFY_MODE=0 into an Integer.
      unless mail.smtp_openssl_verify_mode.nil?
        mode = mail.smtp_openssl_verify_mode
        settings[:openssl_verify_mode] = mode.is_a?(Symbol) ? mode.to_s : mode
      end

      apply_encryption!(settings, mail)
      settings
    end

    def apply_encryption!(settings, mail)
      if implicit_tls?(mail)
        # Implicit TLS (SMTPS), typically port 465. Mail 2.9 raises ArgumentError
        # when :ssl is combined with a truthy STARTTLS flag, and otherwise ignores :ssl.
        settings[:ssl] = true
        settings[:enable_starttls_auto] = false
        settings[:enable_starttls] = false
      else
        settings[:enable_starttls_auto] = mail.smtp_enable_starttls_auto unless mail.smtp_enable_starttls_auto.nil?
        # settings.yml / PWP__MAIL__SMTP_STARTTLS maps to smtp_starttls
        settings[:enable_starttls] = mail.smtp_starttls unless mail.smtp_starttls.nil?
      end
    end

    # Only an explicit true opts in. Upgrades that omit smtp_ssl, and the
    # default false, must keep the previous STARTTLS behavior.
    def implicit_tls?(mail)
      mail.respond_to?(:smtp_ssl) && mail.smtp_ssl == true
    end
  end
end
