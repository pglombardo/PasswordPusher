require 'addressable/uri'

module UrlsHelper
  def valid_url?(url)
      parsed = Addressable::URI.parse(url) or return false
      !parsed.scheme.nil?
  rescue Addressable::URI::InvalidURIError
      false
  end
end
  