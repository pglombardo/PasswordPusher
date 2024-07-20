# Redirects for Pushes#new
["p", "f", "r"].each do |resource|
  # example of a lambda
  # get "/ca/#{resource}/nou(.:format)"), to: redirect { |c| c.key?(:format) ? "/#{resource}/new.#{c[:format]}?locale=ca" : "/#{resource}/new?locale=ca" }
  get CGI.unescape("/ca/#{resource}/nou(.:format)"), to: redirect("/#{resource}/new?locale=ca", status: 301)
  get CGI.unescape("/cs/#{resource}/Nov%C3%BD(.:format)"), to: redirect("/#{resource}/new?locale=cs", status: 301)
  get CGI.unescape("/da/#{resource}/ny(.:format)"), to: redirect("/#{resource}/new?locale=da", status: 301)
  get CGI.unescape("/de/#{resource}/neu(.:format)"), to: redirect("/#{resource}/new?locale=de", status: 301)
  get CGI.unescape("/en/#{resource}/new(.:format)"), to: redirect("/#{resource}/new?locale=en", status: 301)
  get CGI.unescape("/es/#{resource}/nuevo(.:format)"), to: redirect("/#{resource}/new?locale=es", status: 301)
  get CGI.unescape("/eu/#{resource}/berria(.:format)"), to: redirect("/#{resource}/new?locale=eu", status: 301)
  get CGI.unescape("/fi/#{resource}/Uusi(.:format)"), to: redirect("/#{resource}/new?locale=fi", status: 301)
  get CGI.unescape("/fr/#{resource}/nouveau(.:format)"), to: redirect("/#{resource}/new?locale=fr", status: 301)
  get CGI.unescape("/hi/#{resource}/%E0%A4%A8%E0%A4%AF%E0%A4%BE(.:format)"), to: redirect("/#{resource}/new?locale=hi", status: 301)
  get CGI.unescape("/hu/#{resource}/%C3%BAj(.:format)"), to: redirect("/#{resource}/new?locale=hu", status: 301)
  get CGI.unescape("/id/#{resource}/baru(.:format)"), to: redirect("/#{resource}/new?locale=id", status: 301)
  get CGI.unescape("/is/#{resource}/n%C3%BDr(.:format)"), to: redirect("/#{resource}/new?locale=is", status: 301)
  get CGI.unescape("/it/#{resource}/nuovo(.:format)"), to: redirect("/#{resource}/new?locale=it", status: 301)
  get CGI.unescape("/ja/#{resource}/%E6%96%B0%E3%81%97%E3%81%84(.:format)"), to: redirect("/#{resource}/new?locale=ja", status: 301)
  get CGI.unescape("/ko/#{resource}/%EC%83%88%EB%A1%9C%EC%9A%B4(.:format)"), to: redirect("/#{resource}/new?locale=ko", status: 301)
  get CGI.unescape("/lv/#{resource}/jauns(.:format)"), to: redirect("/#{resource}/new?locale=lv", status: 301)
  get CGI.unescape("/nl/#{resource}/nieuw(.:format)"), to: redirect("/#{resource}/new?locale=nl", status: 301)
  get CGI.unescape("/no/#{resource}/ny(.:format)"), to: redirect("/#{resource}/new?locale=no", status: 301)
  get CGI.unescape("/pl/#{resource}/nowy(.:format)"), to: redirect("/#{resource}/new?locale=pl", status: 301)
  get CGI.unescape("/pt-br/#{resource}/novo(.:format)"), to: redirect("/#{resource}/new?locale=pt-br", status: 301)
  get CGI.unescape("/pt-pt/#{resource}/novo(.:format)"), to: redirect("/#{resource}/new?locale=pt-pt", status: 301)
  get CGI.unescape("/ro/#{resource}/nou(.:format)"), to: redirect("/#{resource}/new?locale=ro", status: 301)
  get CGI.unescape("/ru/#{resource}/%D0%BD%D0%BE%D0%B2%D1%8B%D0%B9(.:format)"), to: redirect("/#{resource}/new?locale=ru", status: 301)
  get CGI.unescape("/sr/#{resource}/%D0%9D%D0%BE%D0%B2%D0%B0(.:format)"), to: redirect("/#{resource}/new?locale=sr", status: 301)
  get CGI.unescape("/sk/#{resource}/nov%C3%BD(.:format)"), to: redirect("/#{resource}/new?locale=sk", status: 301)
  get CGI.unescape("/sv/#{resource}/ny(.:format)"), to: redirect("/#{resource}/new?locale=sv", status: 301)
  get CGI.unescape("/th/#{resource}/%E0%B9%83%E0%B8%AB%E0%B8%A1%E0%B9%88(.:format)"), to: redirect("/#{resource}/new?locale=th", status: 301)
  get CGI.unescape("/uk/#{resource}/%D0%BD%D0%BE%D0%B2%D0%B8%D0%B9(.:format)"), to: redirect("/#{resource}/new?locale=uk", status: 301)
  get CGI.unescape("/ur/#{resource}/%D9%86%D8%A6%DB%8C(.:format)"), to: redirect("/#{resource}/new?locale=ur", status: 301)
  get CGI.unescape("/zh-cn/#{resource}/%E6%96%B0%E7%9A%84(.:format)"), to: redirect("/#{resource}/new?locale=zh-CN", status: 301)
end

# Legacy URL support for already shared links
# These will redirect to their Push path equivalents.
get "/:locale/p/:url_token", to: redirect("/p/%{url_token}?locale=%{locale}")
get "/:locale/p/:url_token/r", to: redirect("/p/%{url_token}/r?locale=%{locale}")

get "/:locale/f/:url_token", to: redirect("/f/%{url_token}?locale=%{locale}")
get "/:locale/f/:url_token/r", to: redirect("/f/%{url_token}/r?locale=%{locale}")

get "/:locale/r/:url_token", to: redirect("/r/%{url_token}?locale=%{locale}")
get "/:locale/r/:url_token/r", to: redirect("/r/%{url_token}/r?locale=%{locale}")

# For when we have a unified push
# get "/f/:url_token", to: redirect("/p/%{url_token}")
# get "/f/:url_token/r", to: redirect("/p/%{url_token}/r")
# get "/r/:url_token", to: redirect("/p/%{url_token}")
# get "/r/:url_token/r", to: redirect("/p/%{url_token}/r")

# Redirects for translated routes
I18n.available_locales.each do |locale|
  get "/#{locale.downcase}", to: redirect("/?locale=#{locale.downcase}")
  get "/#{locale.downcase}/api", to: redirect("/api?locale=#{locale.downcase}")
end
