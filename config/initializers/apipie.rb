Apipie.configure do |config|
  config.app_name                = "Password Pusher"
  config.copyright               = "&copy; 2011-Present Peter Giacomo Lombardo"
  config.api_base_url            = ""
  config.doc_base_url            = "/api"
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/**/*.rb"
  config.validate                = false
  config.app_info                = <<-EOS
    The Password Pusher JSON API documentation.


    This API allows for both anonymous and authenticated access.

    To authenticate, get your API token from {the API token page}[/en/users/token] and then apply it in your
    API calls as request headers:


    'X-User-Email': "<email>"
    
    'X-User-Token': "<token>"


    Example:

    curl -X DELETE -H "X-User-Email: <email>" -H "X-User-Token: <token>" https://pwpush.com/p/fkwjfvhall92.json
  EOS
end
