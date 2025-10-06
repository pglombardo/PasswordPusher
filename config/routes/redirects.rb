# Redirect pwpx token path to OSS token path
get "/api_tokens", to: redirect("/users/token", status: 301)
