require 'addressable/uri'

module UrlsHelper
  SCHEMES = %w(http https)
  def valid_url?(url)
      parsed = Addressable::URI.parse(url) or return false
      SCHEMES.include?(parsed.scheme)
  rescue Addressable::URI::InvalidURIError
      false
  end
end
  