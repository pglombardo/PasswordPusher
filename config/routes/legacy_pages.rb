# Redirects for High Voltage Pages
get CGI.unescape("/ca/p%C3%A0gines/:id"), to: redirect("/pages/%{id}?locale=ca", status: 301)
get CGI.unescape("/cs/str%C3%A1nky/:id"), to: redirect("/pages/%{id}?locale=cs", status: 301)
get CGI.unescape("/da/sider/:id"), to: redirect("/pages/%{id}?locale=da", status: 301)
get CGI.unescape("/de/Seiten/:id"), to: redirect("/pages/%{id}?locale=de", status: 301)
get CGI.unescape("/en/pages/:id"), to: redirect("/pages/%{id}?locale=en", status: 301)
get CGI.unescape("/es/paginas/:id"), to: redirect("/pages/%{id}?locale=es", status: 301)
get CGI.unescape("/eu/orrialdeak/:id"), to: redirect("/pages/%{id}?locale=eu", status: 301)
get CGI.unescape("/fi/sivuja/:id"), to: redirect("/pages/%{id}?locale=fi", status: 301)
get CGI.unescape("/fr/pages/:id"), to: redirect("/pages/%{id}?locale=fr", status: 301)
get CGI.unescape("/hi/%E0%A4%AA%E0%A5%83%E0%A4%B7%E0%A5%8D%E0%A4%A0%E0%A5%8B%E0%A4%82/:id"), to: redirect("/pages/%{id}?locale=hi", status: 301)
get CGI.unescape("/hu/oldalakat/:id"), to: redirect("/pages/%{id}?locale=hu", status: 301)
get CGI.unescape("/id/halaman/:id"), to: redirect("/pages/%{id}?locale=id", status: 301)
get CGI.unescape("/is/s%C3%AD%C3%B0ur/:id"), to: redirect("/pages/%{id}?locale=is", status: 301)
get CGI.unescape("/it/pagine/:id"), to: redirect("/pages/%{id}?locale=it", status: 301)
get CGI.unescape("/ja/%E3%83%9A%E3%83%BC%E3%82%B8/:id"), to: redirect("/pages/%{id}?locale=ja", status: 301)
get CGI.unescape("/ko/%ED%8E%98%EC%9D%B4%EC%A7%80/:id"), to: redirect("/pages/%{id}?locale=ko", status: 301)
get CGI.unescape("/lv/lapas/:id"), to: redirect("/pages/%{id}?locale=lv", status: 301)
get CGI.unescape("/nl/Pagina's/:id"), to: redirect("/pages/%{id}?locale=nl", status: 301)
get CGI.unescape("/no/sider/:id"), to: redirect("/pages/%{id}?locale=no", status: 301)
get CGI.unescape("/pl/strony/:id"), to: redirect("/pages/%{id}?locale=pl", status: 301)
get CGI.unescape("/pt-br/P%C3%A1ginas/:id"), to: redirect("/pages/%{id}?locale=pt-br", status: 301)
get CGI.unescape("/pt-pt/P%C3%A1ginas/:id"), to: redirect("/pages/%{id}?locale=pt-pt", status: 301)
get CGI.unescape("/ro/pagini/:id"), to: redirect("/pages/%{id}?locale=ro", status: 301)
get CGI.unescape("/ru/%D1%81%D1%82%D1%80%D0%B0%D0%BD%D0%B8%D1%86%D1%8B/:id"), to: redirect("/pages/%{id}?locale=ru", status: 301)
get CGI.unescape("/sr/%D1%81%D1%82%D1%80%D0%B0%D0%BD%D0%B8%D1%86%D0%B5/:id"), to: redirect("/pages/%{id}?locale=sr", status: 301)
get CGI.unescape("/sv/sidor/:id"), to: redirect("/pages/%{id}?locale=sv", status: 301)
get CGI.unescape("/th/%E0%B8%AB%E0%B8%99%E0%B9%89%E0%B8%B2/:id"), to: redirect("/pages/%{id}?locale=th", status: 301)
get CGI.unescape("/uk/%D1%81%D1%82%D0%BE%D1%80%D1%96%D0%BD%D0%BE%D0%BA/:id"), to: redirect("/pages/%{id}?locale=uk", status: 301)
get CGI.unescape("/ur/%D8%B5%D9%81%D8%AD%D8%A7%D8%AA/:id"), to: redirect("/pages/%{id}?locale=ur", status: 301)
get CGI.unescape("/zh-cn/%E9%A1%B5%E6%95%B0/:id"), to: redirect("/pages/%{id}?locale=zh-CN", status: 301)

# Other High Voltage Pages
get "/:locale/pages/about", to: redirect("/pages/about?locale=%{locale}", status: 301)
get "/:locale/pages/faqs", to: redirect("/pages/faq?locale=%{locale}", status: 301)
get "/:locale/pages/generate_key", to: redirect("/pages/generate_key?locale=%{locale}", status: 301)
get "/:locale/pages/tools", to: redirect("/pages/tools?locale=%{locale}", status: 301)
get "/:locale/pages/translate", to: redirect("/pages/translate?locale=%{locale}", status: 301)
