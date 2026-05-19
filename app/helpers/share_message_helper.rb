# frozen_string_literal: true

module ShareMessageHelper
  # Plain-text message for sharing a push link (preview page and manual copy).
  #
  # @param [Push] push
  # @param [String] secret_url
  # @param [Symbol, String, nil] locale - when nil, uses preview_share_message_locale
  def push_share_message_text(push, secret_url:, locale: nil)
    I18n.with_locale(share_message_locale(push, locale)) do
      notes = [
        share_message_expiration_note(push),
        (passphrase_share_note if push.passphrase.present?),
        I18n._("Once retrieved, the link and content will be deleted upon expiration.")
      ].compact

      [
        I18n._("A secure link has been shared with you."),
        "",
        I18n._("Please find the secret link below to access the sensitive information."),
        "",
        "#{I18n._("Secret link")}: #{secret_url}",
        "",
        I18n._("Important Notes:").upcase,
        *notes.map { |note| "* #{note}" }
      ].join("\n")
    end
  end

  # Locale for share message on preview pages (follows secret link language selector).
  def preview_share_message_locale(_push)
    if params["push_locale"].present? && Settings.enabled_language_codes.include?(params["push_locale"])
      params["push_locale"].to_sym
    else
      I18n.locale
    end
  end

  private

  def share_message_locale(push, locale)
    locale.present? ? locale.to_sym : preview_share_message_locale(push)
  end

  def share_message_expiration_note(push)
    days_label = "#{push.days_remaining} #{n_("day", "days", push.days_remaining)}"
    views_label = "#{push.views_remaining} #{n_("view", "views", push.views_remaining)}"

    I18n._("This link is valid for %{days}, or %{views}, whichever occurs first.") % {days: days_label, views: views_label}
  end

  def passphrase_share_note
    I18n._("For added security, you may be prompted to enter a passphrase (provided separately) to access the content.")
  end
end
