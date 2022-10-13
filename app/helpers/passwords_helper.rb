module PasswordsHelper
  def raw_secret_url(password)
    push_locale = params['push_locale'] || I18n.locale

    if Settings.override_base_url
      raw_url = I18n.with_locale(push_locale) do
        Settings.override_base_url + password_path(password)
      end
    else
      raw_url = I18n.with_locale(push_locale) do
        password_url(password)
      end

      # Support forced https links with FORCE_SSL env var
      raw_url.gsub(/http/i, 'https') if ENV.key?('FORCE_SSL') && !request.ssl?
    end

    raw_url
  end

  def secret_url(password)
    url = raw_secret_url(password)
    url += '/r' if password.retrieval_step
    url
  end
end
