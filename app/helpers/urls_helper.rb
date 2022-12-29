module UrlsHelper
    def url_raw_secret_url(push)
      push_locale = params['push_locale'] || I18n.locale
  
      if Settings.override_base_url
        raw_url = I18n.with_locale(push_locale) do
          Settings.override_base_url + url_path(push)
        end
      else
        raw_url = I18n.with_locale(push_locale) do
          url_url(push)
        end
  
        # Support forced https links with FORCE_SSL env var
        raw_url.gsub(/http/i, 'https') if ENV.key?('FORCE_SSL') && !request.ssl?
      end
  
      raw_url
    end
  
    def url_secret_url(push)
      url = url_raw_secret_url(push)
      url += '/r' if push.retrieval_step
      url
    end

    require 'addressable/uri'
    SCHEMES = %w(http https)
    def valid_url?(url)
        parsed = Addressable::URI.parse(url) or return false
        SCHEMES.include?(parsed.scheme)
    rescue Addressable::URI::InvalidURIError
        false
    end
  end
  